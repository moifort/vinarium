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

What each stack brings today. Every project gets the process rules (`00` to `06`, `08`, `15`,
`16`), the `sentry-autofix` and `stack-upgrade` routines, the `stack-install` and
`stack-upgrade` skills and the base templates, whatever its stacks.

| Stack | Rules | Routines, skills, hook | Templates |
|---|---|---|---|
| `backend` | `09`, `11`, `12`, `14` | `daily-health`, `deprecations`; `domain`, `graphql`, `cold-start` | The server, Terraform, workflows, scripts |
| `ios` | `07`, `10`, `12`, `18` | `deprecations`, `ios-disk-cleanup`; `ios-feature`, `ios-simulator`, `appstore`; the push hook | The app, workflows, fastlane, scripts |
| `android` | `18`, `19` | None | The components check only |
| `ai` | `13` | `ai-calls` | None |
| `site` | `17` | None | None |
| `paid` | None | None | None |
| `admin` | None | None | None |
| `e2e` | None | None | None |

`paid`, `admin` and `e2e` select nothing yet: they state what the project has, and rules `05`
and `15` read `e2e` for the end-to-end gate and its tools.

`init` stops and names every placeholder the chosen stacks use that it cannot derive: pass each
with `--set NAME=value`. Derived ones (name, slug, bundle id, repository) come from the folder
name and can be overridden the same way.

Then, in order, verifying each:
1. `bun run preflight` green.
2. `bun run ios:build` and `bun run ios:test` green (ios stack).
3. Create the GitHub repository, the Sentry projects, the GCP project and its state bucket,
   by hand for now, in the order of rule 14's bootstrap table (the `bootstrap` command that
   does it in one line is not shipped yet), then push the first commit; the Deploy workflow
   does the first deploy. End with the list of what needs the person.
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
