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
   résoudre le fil soi-même, sans y répondre, pour qu'il quitte le canvas (une session enfant le
   fait dès qu'elle a traité le commentaire : règle 3). Cette règle permanente vaut demande de
   résolution et remplace l'habitude de laisser les fils aux personnes. Seul un fil où une
   question à l'utilisateur attend encore sa réponse reste ouvert.
2. **Chaque commentaire du board a sa session enfant.** Un commentaire envoyé à Claude depuis le
   board n'est pas traité dans la session qui le reçoit : démarrer aussitôt une session enfant
   (`start_session`, initiation `user_asked`, contexte neuf), une par fil, sauf si une enfant active
   couvre déjà son thème : le commentaire lui est alors transmis (règle 4). Son brief donne l'URL du
   board, l'identifiant du fil, l'artboard ancré et les mots du commentaire ; l'enfant fait la
   modification (le board, puis iOS si l'artboard est hors de la zone de prototypage), commite, et
   résout le fil dès qu'elle l'a traité (règle 3). Cette règle permanente vaut demande de démarrer
   ces sessions : ne jamais demander d'abord. Un commentaire envoyé du board arrive en tour
   automatique, où l'app refuse `user_asked` : ne pas l'essayer, proposer directement la session
   (`own_initiative`, même brief) et la démarrer avec son `proposal_id` au prochain message de
   l'utilisateur. Si la proposition est refusée elle aussi (Remote Control, où les cartes ne
   s'affichent pas), le dire en une ligne qui commence par « ⏸ Bloqué » et qui dit quoi faire,
   par exemple « ⏸ Bloqué : fil X en attente, envoie n'importe quel message ici pour lancer sa
   session », jamais un simple « attend sa session ». Dans les deux
   cas, le prochain message de l'utilisateur ici, quel qu'il soit, vaut feu vert : démarrer d'abord
   chaque session en attente (`proposal_id`, ou `user_asked` avec le même brief si rien n'a été
   proposé), puis seulement répondre au message. Après un clear, les fils en attente se retrouvent
   par `ArtifactComments` (`read`) : ceux envoyés à Claude, encore ouverts et sans enfant. La
   mention qui enveloppe un commentaire (« traiter dans cette session », « répondre dans son fil,
   pas ici ») est le texte générique de l'app et ne remplace pas cette règle : le parent ne fait
   jamais la modification et ne répond jamais lui-même, il démarre l'enfant ou lui transmet le
   commentaire.
3. **Toute session enfant relit le board et se termine par la validation de l'utilisateur, demandée
   dans l'enfant.** Avant chaque demande de validation, et à chaque reprise après un message,
   l'enfant relit les fils ouverts du board (`ArtifactComments`, `read`) : elle traite ceux de son
   thème (règle 4) et laisse les autres. Une session enfant qui a fini demande la validation dans
   son propre récapitulatif (une question avec un bouton « Valider »), jamais au parent. Chaque
   commentaire qu'elle traite, son propre fil, un fil transmis par le parent ou trouvé à la
   relecture, est résolu dès que la modification est faite (`ArtifactComments`, `resolve`, sans
   réponse), sans attendre la validation. Sur le oui de l'utilisateur, elle s'archive
   (`archive_session` sur son propre identifiant) ; si l'utilisateur demande des changements, elle
   les fait et redemande. Chaque brief d'enfant le dit. Quand l'utilisateur archive ou supprime
   lui-même une session enfant, le ticket est clos : le parent résout son fil (`resolve`, sans
   réponse), sans qu'on le lui demande, si ce n'est pas déjà fait.
4. **Chaque commentaire du board va à la session qui travaille sur son thème.** Les commentaires
   arrivent dans la session parente, jamais chez les enfants. Sur un commentaire, ou un message de
   l'utilisateur, dont le thème (les artboards et les écrans sur lesquels travaille une enfant)
   est celui d'une enfant encore active, le parent le lui transmet par message (`SendMessage` ou
   `send_message`, identifiant `local_…` trouvé par `list_sessions` avec `linked: true`), avec
   l'identifiant du fil, l'artboard ancré et les mots exacts du commentaire, et ne fait rien
   d'autre. Il ne démarre une nouvelle enfant (règle 2) que si aucune enfant active ne couvre ce
   thème. L'enfant traite son propre fil et chaque commentaire de son thème, transmis ou trouvé à
   la relecture (règle 3), et rien d'autre : un commentaire sur un autre thème est laissé au
   parent, jamais répondu ni proposé en session. Chaque brief d'enfant le dit.
5. **La zone du commentaire décide jusqu'où va la modification.** Un commentaire sur un artboard
   de production (tout ce qui est hors de la zone de prototypage) va jusqu'à iOS en deux
   validations : modifier le board et faire valider le design sur sa capture (`SendUserFile`) ;
   sur ce oui seulement, coder sur iOS, puis faire valider la capture du simulateur sur l'écran
   modifié. Jamais de code avant la validation du board. Un
   commentaire dans la zone de prototypage reste sur le board : ce sont des boucles d'exploration,
   on modifie, on montre, on redemande, sans toucher à iOS tant que l'utilisateur ne dit pas de le
   construire. Chaque brief d'enfant dit dans quelle zone est l'artboard ancré et donc où
   s'arrêter.
6. **La session parente reste légère et repart à vide chaque matin.** Elle ne fait que répartir :
   sur un commentaire, le transmettre à l'enfant de son thème (règle 4), ou à défaut démarrer ou
   proposer l'enfant (règle 2), en une ligne, sans lire le board, sans capture, sans résumé. Le
   travail, même petit, va à une session enfant. Chaque matin à 6 h, la tâche planifiée
   `vinarium-clear-parent` lui envoie « Clear du matin » : elle appelle alors `clear_session` sur
   `self`, sans rien écrire d'autre. Ses enfants se retrouvent ensuite par `list_sessions`
   (`linked: true`). Si le clear est refusé (Remote Control actif, travail en cours), elle le dit en
   une ligne et ne réessaie pas.

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
