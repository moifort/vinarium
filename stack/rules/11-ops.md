# Operations

## Deployment goes through CI only

Never `terraform apply`, never a backend deploy, never a migration from the local machine. The
Deploy workflow on a push to `main` is the only path to production: build, `terraform
apply`, then `POST /admin/migrate`. If production looks stale, `gh run list --workflow deploy.yml`
first; fix the pipeline, never the machine.

## Migrations

Forward-only, sequential, no rollback, in `server/system/migration/migrations/`, registered in
its index, tracked in a `migration-meta` collection, triggered by `POST /admin/migrate` from the
Deploy workflow right after `terraform apply`. After a push that adds one, read that step's log
line (`{"outcome":"migrated","from":7,"to":8,"applied":1}`) instead of telling anyone to run it.

Between the push and the end of the deploy, a local server runs new code against unmigrated data:
errors in that window are expected.

**Migrate when** renaming a field, changing its structure, changing enum values, removing stale
data. **No migration** for a new optional field, a new collection, or changed query logic. Every
migration has its `.int.test.ts`.

## Indexes

Indexes follow queries: when a query changes, add the indexes it needs and drop the dead ones.
Only the necessary: a sort done in memory after the read needs none. The index file is the source
of truth read by Terraform, not a console action.

## API evolution

The GraphQL schema is not versioned: installed builds keep asking for what they were built
against, for weeks after a release. So the schema only grows, and what the app stops using leaves
in two steps.

1. **Deprecate, in the commit where the app stops asking.** The operations stop selecting the
   field or argument; the server marks it with a `deprecationReason` that names the version and
   the date it was deprecated and what replaces it (`"since 1.3 (2026-10-21): use coverSources"`).
   The resolver keeps working. `bun run schema:check` in CI refuses any breaking change that
   was not deprecated first.
2. **Remove, once no build on sale asks for it.** `bun run deprecations` finds, for each
   deprecated element, the first build whose operations no longer select it and compares it
   with what the store sells: removable when a build without it has been on sale for **fourteen
   days**, in grace until then, waiting while the store still sells a build that asks for it.
   One commit removes the removable elements (schema, resolver, the code and tests only they
   used) and raises the minimum supported build to the floor the script proposes, which sends
   older builds to the update screen at their next launch. Several releases in one day change
   nothing: the fourteen days count from the release that stopped asking, not from the next one.

The removal runs as a **scheduled routine** (monthly by default, see
[16-routines.md](16-routines.md)), and may be run by hand at a release. The comparison key is the
build number, never the marketing version. The gate fails open: if the configuration is
unreachable, the app stays usable. A deploy whose floor is above the build on sale fails: readers
must never be blocked with no update to install.

| Change | Breaks installed builds | What to do |
|---|---|---|
| Added field, query, mutation, optional argument, enum value | No | Nothing: an unknown enum value is read as a neutral one by the app |
| Field or argument the app stops using | No | Deprecate it in the same commit |
| Removal, rename, type change, argument made required, non-null made nullable | Yes | Deprecate first; the routine removes it fourteen days after a build without it is on sale |

## Scale to zero

Never a warm instance (`min_instance_count`), whatever the p95 says. Scaling to zero is the point;
cold starts are absorbed by the launch screen, and when traffic grows the users keep instances
warm. A p95 driven by cold starts is a figure to report, not an action item.

What is worked on instead is the cold start itself, measured before it is changed:

- `server/system/boot-marks.ts` logs one `boot steps` line per instance (time before the
  bundle, the rest of the bundle, Sentry, the GraphQL server): read it from production logs to
  choose what to load later.
- The production bundle inlines its dependencies, except the Firebase, gRPC and Sentry packages
  (`externals` in `nitro.config.ts`): thousands of files in `node_modules` were most of a cold
  start.
- Firestore talks REST (`preferRest`), so the first read does not load gRPC; Sentry runs with
  `enableRuntimeChannelInjection: false`, which skips a module loader hook that produced no span.
- Concurrency per instance is sized on memory, not CPU (`max_instance_request_concurrency` in
  `infra/function.tf`, mirrored in `nitro.config.ts`): sixteen on 1 GiB, since requests mostly
  wait on Firestore and the models.
- Measure locally without deploying: `bun run build`, run `.output/server` under
  `@google-cloud/functions-framework` with `node`, read the `boot steps` line, alternate the two
  builds a dozen times and compare medians. A Mac is about six times faster than Cloud Run on
  the dependency load: scale the gain, and say it is an estimate.

## Monitoring and Sentry

One Sentry project per side (`<app>-node`, `<app>-ios`), org `polyforms`. Triage of an issue:

1. Load the token from the local environment, never print or commit it.
2. Read the issue and its latest event through the API.
3. Walk the stack to the domain code, fix the cause, not the symptom.
4. For a serious functional bug, write the failing test before the fix.
5. Verify locally, commit.
6. Mark the issue `resolvedInNextRelease` (never plain `resolved`, so a regression is flagged)
   only after the push **and** a green pipeline.

Source maps upload is part of the release workflow, never asked again.

## Backups and recovery

The `(default)` database has delete protection and seven-day point-in-time recovery. Until the
app has paying users, there is no backup outside it; from the first paying user, a weekly
managed export of the database to a bucket of the project (`gcloud firestore export`, run by
Cloud Scheduler, 90-day lifecycle on the bucket) is provisioned by Terraform: a deletion found on
the eighth day is then still recoverable. When data is lost (deleted documents, a failed
migration, a deleted database or project) follow the project's `docs/data-recovery.md` before
acting, and never restore the whole database over live writes.

## Secrets

A secret lives in the gitignored local `.env`, with `.env.example` beside it, and in the CI's
secret store. The chain to production: GitHub secret, Terraform variable, Secret Manager, function
environment. Every place a token is replicated is listed in `project-context.md`; a rotation that
forgets one is found by an outage. A local API key is distinct from production's; keys are
compared by fingerprint (`printf '%s' "$k" | shasum`), never displayed.

## Dependencies

Renovate, self-hosted in a nightly workflow: `config:recommended`, non-major updates grouped in
one pull request automerged when CI is green, weekly lockfile maintenance. Every
`allowedVersions` bound carries its reason in `description` (a peer dependency the deploy's
stricter package manager rejects, a framework not yet on the new major). A strict install
replayed on the build artefact catches what the permissive local install let through.

**Majors are never automerged.** The upgrade routine ([16-routines.md](16-routines.md)) takes
every open major pull request each morning: it reads the dependency's changelog and migration
guide, applies the code changes the new major requires, deploys the branch to the project's
staging environment ([14-infra.md](14-infra.md#staging)) to prove the build and the deploy, and
merges when CI and the staging deploy are green; otherwise it leaves the pull request open with a
comment saying what blocks. The package of this stack follows the same path with its own label,
`stack`.
