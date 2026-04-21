# Cave-a-Vin — Terraform infrastructure

This module provisions the entire Firebase stack for Cave-a-Vin from a
greenfield GCP project: project itself, Firebase enablement, Firestore
(Native), security rules + indexes, Identity Platform with Apple OAuth,
the iOS Firebase app (and downloads `GoogleService-Info.plist`), the
secrets in Secret Manager, and the Cloud Function Gen 2 that runs the
Nitro/GraphQL backend.

## Prerequisites

- `gcloud` CLI authenticated with Application Default Credentials:
  `gcloud auth application-default login`
- `terraform >= 1.6`
- `bun` (used by the `bootstrap.sh` driver to build the Nitro bundle)
- An Apple Developer account with a Service ID and a `.p8` private key
  (Sign in with Apple). See `ios/FIREBASE_SETUP.md` for the exact steps.
- A GCP billing account id and either an `org_id` or `folder_id`.

## One-time bootstrap

```bash
cp infra/terraform.tfvars.example infra/terraform.tfvars
# Edit terraform.tfvars: project_id, billing, Apple, secrets
cp ~/Downloads/AuthKey_KEY1234567.p8 infra/

# From repo root
make bootstrap
```

The `bootstrap.sh` driver:

1. validates prerequisites,
2. runs `bun install + bun run generate:graphql + bun run build`,
3. runs `terraform init && terraform apply -auto-approve`,
4. POSTs `/admin/migrate` with the generated admin token,
5. prints the Cloud Function URL and the iOS plist path.

End state after a fresh bootstrap: backend operational, Firestore ready,
Apple Sign-In configured, `ios/CaveAVin/GoogleService-Info.plist` written.

## Subsequent deploys (CI)

Every push to `main` runs `.github/workflows/deploy.yml`, which builds the
Nitro bundle and runs `terraform apply` against the same state stored in
GCS. Only the function source archive changes between runs, so the diff
is minimal.

## Teardown

```bash
make destroy
```

Removes the Cloud Function, Firestore data, project, and everything else
created by this module. The project will retain billing for ~30 days
after deletion (GCP soft-delete).
