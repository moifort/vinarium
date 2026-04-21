#!/usr/bin/env bash
#
# bootstrap.sh — one-shot local provisioning of the Cave-a-Vin Firebase stack.
#
# Run this ONCE on a clean machine. Subsequent deploys go through GitHub
# Actions (.github/workflows/deploy.yml) which talks to the same Terraform
# state stored in GCS.
#
# Required CLIs: gcloud, terraform (>= 1.6), bun, curl, jq.
# Required files: infra/terraform.tfvars (copy from terraform.tfvars.example
# and fill in), and the Apple .p8 file at the path declared in tfvars.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFRA_DIR="${REPO_ROOT}/infra"
TFVARS="${INFRA_DIR}/terraform.tfvars"

step() { printf "\n\033[1;34m▸ %s\033[0m\n" "$*"; }
ok()   { printf "\033[1;32m✓\033[0m %s\n" "$*"; }
fail() { printf "\033[1;31m✗\033[0m %s\n" "$*" >&2; exit 1; }

# --------------------------------------------------------------------------- 1
step "Checking prerequisites"

for cmd in gcloud terraform bun curl jq; do
  command -v "$cmd" >/dev/null 2>&1 || fail "Missing required CLI: $cmd"
done
ok "All required CLIs present"

[[ -f "$TFVARS" ]] || fail "$TFVARS missing — copy from terraform.tfvars.example"
ok "terraform.tfvars present"

# Read the Apple .p8 path from tfvars and resolve it relative to infra/
APPLE_P8_REL=$(grep -E '^\s*apple_private_key_path\s*=' "$TFVARS" | sed -E 's/.*=\s*"(.*)"/\1/')
APPLE_P8_ABS="$INFRA_DIR/$(echo "$APPLE_P8_REL" | sed 's|^\./||')"
[[ -f "$APPLE_P8_ABS" ]] || fail "Apple private key not found at $APPLE_P8_ABS"
ok "Apple .p8 found"

gcloud auth application-default print-access-token >/dev/null 2>&1 \
  || fail "gcloud ADC not configured. Run: gcloud auth application-default login"
ok "gcloud Application Default Credentials OK"

# --------------------------------------------------------------------------- 2
step "Building the Nitro bundle (firebase preset, Gen 2)"

cd "$REPO_ROOT"
bun install --frozen-lockfile
bunx nitro prepare
bun run generate:graphql
bun run build
ok "Build complete: .output/server/"

# --------------------------------------------------------------------------- 3
step "Provisioning the GCP project + Firebase stack with Terraform"

cd "$INFRA_DIR"

# First-time init uses local state (no backend.tf yet).
if [[ ! -f backend.tf ]]; then
  terraform init -input=false
else
  terraform init -input=false -reconfigure
fi

terraform apply -auto-approve -input=false
ok "terraform apply succeeded"

# --------------------------------------------------------------------------- 4
step "Migrating Terraform state to GCS"

TFSTATE_BUCKET=$(terraform output -raw tfstate_bucket)

if [[ ! -f backend.tf ]]; then
  cat > backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "${TFSTATE_BUCKET}"
    prefix = "cave-a-vin"
  }
}
EOF
  terraform init -migrate-state -force-copy -input=false
  ok "State migrated to gs://${TFSTATE_BUCKET}/cave-a-vin"
  echo "   Commit infra/backend.tf so the CI can read the same state."
else
  ok "Remote state already configured"
fi

# --------------------------------------------------------------------------- 5
step "Running Firestore migrations against the freshly deployed function"

FN_URL=$(terraform output -raw function_url)
ADMIN_TOKEN=$(terraform output -raw admin_token)

curl -fsS -X POST \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  "${FN_URL}/admin/migrate" \
  | jq .
ok "Migrations applied"

# --------------------------------------------------------------------------- 6
step "Summary"

PROJECT_ID=$(terraform output -raw project_id)
IOS_PLIST=$(terraform output -raw ios_plist_path)

cat <<EOF

  Project              : ${PROJECT_ID}
  Cloud Function URL   : ${FN_URL}
  iOS GoogleService    : ${IOS_PLIST}
  Terraform state      : gs://${TFSTATE_BUCKET}/cave-a-vin
  Admin token (sensitive, store in GitHub secret ADMIN_TOKEN):
                         ${ADMIN_TOKEN}

  Next steps
  ----------
  1. Commit infra/backend.tf so .github/workflows/deploy.yml uses the same
     remote state.
  2. Add the following GitHub secrets / variables:
       Secrets : GCP_BILLING_ACCOUNT, GCP_WIF_PROVIDER, GCP_DEPLOY_SA,
                 APPLE_TEAM_ID, APPLE_SERVICES_ID, APPLE_KEY_ID,
                 APPLE_PRIVATE_KEY_P8, ANTHROPIC_API_KEY, GEMINI_API_KEY,
                 SENTRY_DSN, ADMIN_TOKEN
       Vars    : GCP_PROJECT_ID (= ${PROJECT_ID}), GCP_ORG_ID
  3. In Xcode, follow ios/FIREBASE_SETUP.md to add the SPM packages
     (Apollo iOS, Firebase iOS), enable the Sign in with Apple capability,
     and run apollo-ios-cli generate.
  4. Push to main — the deploy workflow will redeploy the Cloud Function on
     every commit.

EOF
