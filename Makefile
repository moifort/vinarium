.PHONY: help bootstrap build infra-init plan apply destroy

help:
	@echo "Cave-a-Vin — common targets"
	@echo ""
	@echo "  make bootstrap   One-shot local provisioning (run once on a fresh project)"
	@echo "  make build       Build the Nitro bundle for the Cloud Function"
	@echo "  make plan        terraform plan (after build)"
	@echo "  make apply       terraform apply (after build)"
	@echo "  make destroy     Tear down the entire stack"

bootstrap:
	./scripts/bootstrap.sh

build:
	bun install --frozen-lockfile
	bunx nitro prepare
	bun run generate:graphql
	bun run build

infra-init:
	cd infra && terraform init

plan: build
	cd infra && terraform plan

apply: build
	cd infra && terraform apply

destroy:
	./scripts/teardown.sh
