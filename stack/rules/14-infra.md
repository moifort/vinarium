# Infrastructure

Terraform in `infra/`, one GCP project per app named `<app>-polyforms`, region `europe-west3`,
Firestore `eur3`. Templates in `templates/infra/`.

| File | What it provisions |
|---|---|
| `project.tf`, `versions.tf`, `state.tf`, `backend.tf` | The project, the providers, the remote state bucket |
| `firebase.tf`, `auth.tf` | The Firebase app, Sign in with Apple |
| `firestore.tf` | The database with delete protection and point-in-time recovery, the indexes |
| `function.tf` | The Cloud Function gen 2 (Node 22) serving the Nitro build, scale to zero |
| `secrets.tf`, `variables.tf` | Secret Manager entries fed by Terraform variables from GitHub secrets |
| `cicd.tf` | Workload Identity Federation for the GitHub workflows |
| `scheduler.tf` | Cloud Scheduler jobs calling the backend's scheduled routes |
| `storage.tf` | Buckets for uploads, signed URLs |
| `ios.tf` | Resources the app needs (APNs key, bundle configuration) |
| `observer.tf` | A read-only service account for unattended production reads |
| `outputs.tf` | What the workflows and the app read back |

## Staging

Every app has a second GCP project, `<app>-staging-polyforms`, provisioned by the same Terraform
(a workspace, same files, smaller quotas), scale to zero so it costs nothing idle. It is the
production-like environment where anything is proven before production: a pull request labelled
`staging` (every major dependency bump, every stack upgrade, anything touching infrastructure) is
deployed there by the Deploy workflow; the end-to-end scenarios and any test that needs a real
stack run against it; a seeded dataset and its own Sentry environment; the app points at it
through its server-URL override. Nothing in staging is ever production data.

It exists from the moment an app has real users to protect, and in any case before the first
paid plan: with a handful of readers, production is the staging. Bazar is built with it from the
start.

## Bootstrap: one line creates a project

`bunx @moifort/stack bootstrap <app>` runs once from the person's machine and leaves a project
that deploys itself. It is a command of the package's CLI (TypeScript on Bun, like the rest), not
a shell script: it reads the keychain, drives `terraform` (installed once on the machine, see
[15-tooling.md](15-tooling.md)), `gh` and `git`, and reports. Two Terraform roots, because two
kinds of credentials:

| Root | Runs | Credentials | Creates |
|---|---|---|---|
| `infra/org/` | From the machine, at bootstrap and when the organisation-level setup changes | The person's organisation tokens, read from the macOS keychain for the duration of the run | The GitHub repository (settings, Pages, labels, branch rules), its secrets and variables, the Sentry projects (`<app>-node`, `<app>-ios`) with their DSNs written straight into the GitHub secrets, the Renovate installation, the GCP project and the state bucket |
| `infra/` | By the Deploy workflow, through Workload Identity Federation | None on the machine | Everything in the table above |

- **Keychain, not files.** The organisation tokens (GitHub, Sentry, App Store Connect) live in
  the macOS keychain under fixed item names (`polyforms.github`, `polyforms.sentry`,
  `polyforms.asc`), read with `security find-generic-password -w` into the environment of the
  bootstrap process only, never written to a file, never printed, never committed. Each token is
  fine-grained and scoped to the organisation, with an expiry, and its creation date is in the
  person's `project-context.md`.
- **The CI never holds a personal token.** What a workflow needs at run time is a repository
  secret Terraform wrote (a DSN, a store API key) or a token it mints itself: Renovate runs
  with a GitHub App installed on the organisation (the workflow mints a short-lived token from
  the app's private key, stored once as an organisation secret), not with a personal token
  that expires.
- **Replayable.** Every step of the bootstrap checks whether it is already done and skips it,
  so a run that failed halfway is simply run again. It never deploys the backend itself: it
  ends by pushing the first commit and letting the Deploy workflow do the first deploy.
- **What it cannot do, it lists.** The bootstrap ends with a numbered list of the steps that
  need the person: the App Store Connect app record and the Sign in with Apple key (no API),
  the Apple developer agreement, the DNS of the project's domain, the GA4 link when the API
  refuses it. Each item says where to click and what value to paste back.
- `bunx @moifort/stack teardown <app>` destroys both roots, after a typed confirmation of the
  app's name.

## Rules

- The Terraform state is remote and never committed. `terraform.tfvars` is gitignored, with its
  `.example`.
- Secrets reach the function through Secret Manager only; the workflow never writes a key into
  an environment file.
- **One observer account for Claude, across every project** of the organisation
  (`claude-observer`, in the neutral `polyforms-billing` project below), granted the read roles
  (logging, monitoring, scheduler, functions, run, Firestore viewer, BigQuery job user and data
  viewer) on each app project by that project's Terraform. Writes answer permission denied,
  checked. It lives in its own `gcloud` configuration (`CLOUDSDK_CONFIG`) so the person's
  account is untouched and routines do not depend on their login, which expires. Its key is on
  the machine only, outside every repository.
- **A neutral `polyforms-billing` GCP project** holds the billing export dataset and the
  observer account, so that deleting an app never takes the invoice or the reader of every
  other app with it. Each project's runtime account gets `dataViewer` on the dataset through SQL
  `GRANT`, the IAM binding command being allowlisted. (Today the export lives in Vinarium's
  project: moving it is a migration of this package.)
- Analytics: the Firebase project is linked to a GA4 property at creation, or sessions go
  nowhere; the property id is a repository variable.
- Never a warm instance, see [11-ops.md](11-ops.md#scale-to-zero).
- APNs keys and Sign in with Apple keys live in `infra/`, gitignored; they are not the store API
  key.
