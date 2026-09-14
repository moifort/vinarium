# Vinarium - Project Directives

## Playbook

La méthode de travail est dans [playbook/](playbook/README.md). Ces fichiers font autorité ; ce
document ne contient que ce qui est propre au projet.

| Sujet | Fichier |
|---|---|
| Comportement, langues, autonomie | [playbook/00-collaboration.md](playbook/00-collaboration.md) |
| Cycle d'une tâche, plans, skills | [playbook/01-workflow.md](playbook/01-workflow.md) |
| Commits, branche, push | [playbook/02-commits.md](playbook/02-commits.md) |
| Revue avant commit | [playbook/03-code-review.md](playbook/03-code-review.md) |
| Check-list de push | [playbook/04-push-protocol.md](playbook/04-push-protocol.md) |
| Release par tag | [playbook/05-release.md](playbook/05-release.md) |
| Changelog | [playbook/06-changelog.md](playbook/06-changelog.md) |
| Soumission App Store | [playbook/07-appstore.md](playbook/07-appstore.md) |
| Copy utilisateur | [playbook/08-copywriting.md](playbook/08-copywriting.md) |
| Backend | [playbook/09-backend.md](playbook/09-backend.md) |
| iOS | [playbook/10-ios.md](playbook/10-ios.md) |
| Exploitation | [playbook/11-ops.md](playbook/11-ops.md) |

Les faits propres au projet (identifiants, accès, certificats, travaux en attente) sont dans
[project-context.md](project-context.md).

## Commandes

| But | Commande |
|---|---|
| Préflight avant commit ou push | `bun run preflight` |
| Vérification de types | `bun run typecheck` (inclut `nitro prepare`) |
| Tests | `bun test` |
| Couverture | `bun test --coverage` |
| Linter | `bun run lint` / `bun run lint:fix` |
| Build backend | `bun run build` |
| Build iOS | `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/Vinarium.xcodeproj -scheme Vinarium -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build` |
| Scénarios de bout en bout | `./scripts/e2e.sh` (voir [docs/e2e.md](docs/e2e.md)) |
| Captures | `./scripts/screenshots.sh [all\|<lang>…]` puis `bun scripts/generate-appstore-previews.ts` |
| Schéma GraphQL | `bun run generate:graphql`, puis `cd ios && apollo-ios-cli generate` |
| Installation sur l'iPhone | `scripts/install-device.sh` (proposer, ne jamais lancer sans accord) |

Runtime : toujours `bun` / `bunx`, jamais `npm` / `npx`.

## Spécificités

- Branche principale `main`, tag de release `ios-v<version>`.
- Cible iOS 26.0, Swift 6 en concurrence stricte. Simulateur de référence : iPhone 17, iOS 26.2.
- Build App Store avec le dernier Xcode **final** (26.6 / `17F113`, SDK `23F81a`), jamais une
  beta ni une version dépassée. `DEVELOPER_DIR` est requis parce que `xcode-select` pointe sur les
  Command Line Tools.
- Le Mac de développement tourne sur un macOS beta : après `xcodebuild archive` et avant
  `-exportArchive`, corriger l'empreinte de machine avec le dernier build public relevé sur
  https://developer.apple.com/news/releases.
  ```bash
  plutil -replace BuildMachineOSBuild -string '<build public>' \
    build/Vinarium.xcarchive/Products/Applications/Vinarium.app/Info.plist
  ```
- Langue source de la copy : anglais pour `CHANGELOG.md`, sept langues servies. Les notes
  **françaises** sont validées par Thibaut avant tout push de release.
- Migrations : `server/system/migration/`, déclenchées par `POST /admin/migrate` depuis la CI.
  Guide : [docs/migrations.md](docs/migrations.md).
- Documentation technique détaillée : [docs/](docs/), notamment
  [architecture.md](docs/architecture.md), [domain-guide.md](docs/domain-guide.md),
  [ios-guide.md](docs/ios-guide.md), [screenshots.md](docs/screenshots.md).
- Checklist complète de soumission : [ios/APP_STORE_SUBMISSION.md](ios/APP_STORE_SUBMISSION.md).
