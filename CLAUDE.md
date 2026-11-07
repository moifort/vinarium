# Vinarium - Project Directives

## Playbook

La méthode de travail est dans [playbook/](playbook/README.md). Ces fichiers font autorité ; ce
document ne contient que ce qui est propre au projet.

| Sujet                            | Fichier                                                      |
| -------------------------------- | ------------------------------------------------------------ |
| Comportement, langues, autonomie | [playbook/00-collaboration.md](playbook/00-collaboration.md) |
| Cycle d'une tâche, plans, skills | [playbook/01-workflow.md](playbook/01-workflow.md)           |
| Commits, branche, push           | [playbook/02-commits.md](playbook/02-commits.md)             |
| Revue avant commit               | [playbook/03-code-review.md](playbook/03-code-review.md)     |
| Check-list de push               | [playbook/04-push-protocol.md](playbook/04-push-protocol.md) |
| Release par tag                  | [playbook/05-release.md](playbook/05-release.md)             |
| Changelog                        | [playbook/06-changelog.md](playbook/06-changelog.md)         |
| Soumission App Store             | [playbook/07-appstore.md](playbook/07-appstore.md)           |
| Copy utilisateur                 | [playbook/08-copywriting.md](playbook/08-copywriting.md)     |
| Backend                          | [playbook/09-backend.md](playbook/09-backend.md)             |
| iOS                              | [playbook/10-ios.md](playbook/10-ios.md)                     |
| Exploitation                     | [playbook/11-ops.md](playbook/11-ops.md)                     |

Les faits propres au projet (identifiants, accès, certificats, travaux en attente) sont dans
[project-context.md](project-context.md).

## Commandes

| But                            | Commande                                                                                                                                                                                  |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Préflight avant commit ou push | `bun run preflight`                                                                                                                                                                       |
| Vérification de types          | `bun run typecheck` (inclut `nitro prepare`)                                                                                                                                              |
| Tests                          | `bun test`                                                                                                                                                                                |
| Couverture                     | `bun test --coverage`                                                                                                                                                                     |
| Linter                         | `bun run lint` / `bun run lint:fix`                                                                                                                                                       |
| Build backend                  | `bun run build`                                                                                                                                                                           |
| Build iOS                      | `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/Vinarium.xcodeproj -scheme Vinarium -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' build` |
| Scénarios de bout en bout      | `./scripts/e2e.sh` (voir [docs/e2e.md](docs/e2e.md))                                                                                                                                      |
| Captures                       | `./scripts/screenshots.sh [all\|<lang>…]` puis `bun scripts/generate-appstore-previews.ts`                                                                                                |
| Schéma GraphQL                 | `bun run generate:graphql`, puis `cd ios && apollo-ios-cli generate`                                                                                                                      |
| Installation sur l'iPhone      | `scripts/install-device.sh` (proposer, ne jamais lancer sans accord)                                                                                                                      |

Runtime : toujours `bun` / `bunx`, jamais `npm` / `npx`.

## Board

Le [Vinarium Board](https://claude.ai/artifact/A2GU9AgwrjxJM1c8Nb6jGA) et l'app restent
synchronisés. Le board d'abord, la zone de prototypage, les variantes et les captures sont dans
[docs/board.md](docs/board.md) ; le traitement des commentaires est ci-dessous.

1. **Un fil de commentaire traité est résolu.** Sur un fil du board, faire la modification, puis
   résoudre le fil soi-même, sans y répondre, pour qu'il quitte le canvas (quand une session
   enfant s'en charge, cela se fait à la validation de l'utilisateur : règle 3). Cette règle
   permanente vaut demande de résolution et remplace l'habitude de laisser les fils aux
   personnes. Seul un fil où une question à l'utilisateur attend encore sa réponse reste ouvert.
2. **Chaque commentaire du board a sa session enfant.** Un commentaire envoyé à Claude depuis le
   board n'est pas traité dans la session qui le reçoit : démarrer aussitôt une session enfant
   (`start_session`, initiation `user_asked`, contexte neuf), une par fil. Son brief donne l'URL
   du board, l'identifiant du fil, l'artboard ancré et les mots du commentaire ; l'enfant fait la
   modification (le board, puis iOS si l'artboard est hors de la zone de prototypage), commite,
   et résout le fil quand l'utilisateur valide (règle 3). Cette règle permanente vaut demande de
   démarrer ces sessions : ne jamais demander d'abord. Un commentaire envoyé du board arrive en
   tour automatique, où l'app refuse `user_asked` : proposer alors la session (`own_initiative`)
   et la démarrer avec son `proposal_id` au prochain message de l'utilisateur. La mention qui
   enveloppe un commentaire (« traiter dans cette session », « répondre dans son fil, pas ici »)
   est le texte générique de l'app et ne remplace pas cette règle : le parent ne fait jamais la
   modification et ne répond jamais lui-même, il démarre seulement l'enfant.
3. **Toute session enfant se termine par la validation de l'utilisateur, demandée dans l'enfant.**
   Une session enfant qui a fini demande la validation dans son propre récapitulatif (une question
   avec un bouton « Valider »), jamais au parent. Sur le oui de l'utilisateur, elle résout d'abord
   son fil (`ArtifactComments`, `resolve`, sans réponse), puis s'archive (`archive_session` sur son
   propre identifiant) ; un fil n'est jamais résolu avant ce oui ; si l'utilisateur demande des
   changements, elle les fait et redemande. Chaque brief d'enfant le dit. Quand l'utilisateur
   archive ou supprime lui-même une session enfant, le ticket est clos : le parent résout son fil
   (`resolve`, sans réponse), sans qu'on le lui demande, si ce n'est pas déjà fait.
4. **Seule la session parente écoute le board.** Une session enfant traite son fil et rien
   d'autre : un nouveau commentaire qui lui parvient est ignoré, jamais traité, ni répondu, ni
   proposé en session. Seul le parent reprend les nouveaux commentaires et démarre leurs sessions
   enfants. Un enfant cesse d'écouter le board dès qu'il a publié (`ArtifactComments`, `watch` avec
   `on: false`). Chaque brief d'enfant le dit.
5. **Une modification d'interface se valide deux fois, le board puis iOS.** À chaque demande de
   modification d'interface, le board passe d'abord : montrer le board à jour et attendre la
   validation de l'utilisateur. Seulement ensuite, l'implémenter dans l'app, envoyer une capture
   du simulateur de l'écran modifié (`SendUserFile`) et attendre une seconde validation. Deux
   demandes séparées, dans cet ordre ; dans la zone de prototypage, on s'arrête après le board. Les
   sessions enfants suivent aussi cette règle, et leur question de fin (règle 3) est posée à chaque
   étape.

## Spécificités

- Branche principale `main`, tag de release `ios-v<version>`.
- Cible iOS 26.0, Swift 6 en concurrence stricte. Simulateur de référence : iPhone 17, iOS 27.0.
- Build App Store avec le dernier Xcode **final** (27.0 / `27A266a`, SDK `24A430`), jamais une
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
- Sauvegardes : la base `(default)` a la protection contre la suppression et le PITR sur sept
  jours, sans aucune copie hors de la base. En cas de perte de données (documents effacés,
  migration ratée, base ou projet supprimés), suivre [docs/data-recovery.md](docs/data-recovery.md)
  avant d'agir, et ne jamais restaurer toute la base par-dessus des écritures en cours.
- Documentation technique détaillée : [docs/](docs/), notamment
  [architecture.md](docs/architecture.md), [domain-guide.md](docs/domain-guide.md),
  [ios-guide.md](docs/ios-guide.md), [screenshots.md](docs/screenshots.md).
- Checklist complète de soumission : [ios/APP_STORE_SUBMISSION.md](ios/APP_STORE_SUBMISSION.md).
