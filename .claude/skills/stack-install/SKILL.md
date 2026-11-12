---
name: stack-install
description: Use to start a new Polyforms project, or to bring an existing project onto the @moifort/stack package (init, templates, Renovate, CI check, routines).
---

# Install the stack

## New project

```bash
mkdir <app> && cd <app> && git init
bunx @moifort/stack init --stacks backend,ios --set APP_TAGLINE="..."
bun install
```

Stacks: `backend`, `ios`, `ai`, `paid`, `admin`, `e2e`, `site`. `init` asks for every
placeholder the chosen stacks use that it cannot derive; derived ones (name, slug, bundle id,
repository) come from the folder name and can be overridden with `--set NAME=value`.

Then, in order, verifying each:
1. `bun run preflight` green.
2. `bun run ios:build` and `bun run ios:test` green (ios stack).
3. `bunx @moifort/stack bootstrap <app>` creates GitHub, Sentry, Renovate, GCP, and pushes
   the first commit; the Deploy workflow does the first deploy. It ends with the list of
   what needs the person.
4. Write the deployed function URL into `ios/<App>/Shared/APIClient.swift`.
5. Create or update the scheduled routines from `stack/routines/` (rule 16).
6. Fill `project-context.md`.

## Existing project

Never `init` in an existing app: it writes every template file the project lacks, which adds a
second app skeleton (`App.swift`, a home, settings) beside the real one. Instead:

1. `bunx stack placeholders --stacks <stacks>` lists the values the stacks need; write
   `stack.config.json` by hand (`stacks`, `placeholders` read from the project: bundle id, team,
   App Store id, server URL, languages, billing table; `exclude: []`).
2. `bun add -d @moifort/stack@<version>`, then `bunx stack sync`: rules into `stack/`, the
   rules block at the top of `CLAUDE.md`, skills and hooks into `.claude/`.
3. `.gitignore` keeps `.claude/skills/`, `.claude/hooks/` and `.claude/settings.json` tracked
   (`.claude/*` then the three `!` lines), so every session and every clone has them.
4. Replace the project's own copy of the method (a `playbook/`, long sections of `CLAUDE.md`)
   with the stack: delete it, point its links at `stack/rules/`, keep in `CLAUDE.md` only what is
   specific to the project, and move a rule found there and missing from the stack into this
   package first.
5. Apply the migrations of every version up to the installed one (`bunx stack migrations 0.0.0
   <version>`), then write a batched plan, one batch per domain (CI, Terraform, Sentry, iOS
   shell, scripts), comparing each file with its template (`templates/` in the package) and
   bringing the project in line batch by batch, each batch verified and committed on its own.
