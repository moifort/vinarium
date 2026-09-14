# dev-playbook

Le socle méthodologique que je réutilise d'un projet à l'autre : comment on travaille, comment on
commite, ce qui se passe à un push, ce qui se passe à une release, comment s'écrit un changelog,
comment se soumet une application. Des fichiers markdown, rien d'autre. On les recopie dans un
projet neuf, on remplit les placeholders, et le projet hérite de la méthode.

## Les trois étages

| Étage | Fichiers | Portée |
|---|---|---|
| Process | `00` à `08` | Tout projet, quelle que soit la stack |
| Stack | `09` à `11` | Les projets qui partagent la stack (backend TypeScript, application iOS) |
| Annexes | `90` à `93` | Formes longues, consultées à la demande, jamais chargées d'office |

| Fichier | Contenu |
|---|---|
| `00-collaboration.md` | Comportement attendu : concision, avis critique, autonomie, langues |
| `01-workflow.md` | Cycle d'une tâche, contenu d'un plan, usage des skills |
| `02-commits.md` | Format des commits, granularité, branche, push |
| `03-code-review.md` | Revue inline avant commit, grille, réception d'une critique |
| `04-push-protocol.md` | Check-list de push et vérification des pipelines |
| `05-release.md` | Release par tag, gate de tests, versionnement |
| `06-changelog.md` | Changelog multilingue, structure, validation |
| `07-appstore.md` | Soumission mobile, signing, captures, ordre des envois |
| `08-copywriting.md` | Ton user-facing, interdits, localisation |
| `09-backend.md` | Règles backend : domaines, types, erreurs, stockage, tests |
| `10-ios.md` | Règles iOS : structure, chargements, build, appareil |
| `11-ops.md` | Migrations, index, monitoring, dépendances, secrets |
| `90-annexe-domaine.md` | Créer un domaine de bout en bout |
| `91-annexe-graphql.md` | Schéma, résolveurs, évolution d'API |
| `92-annexe-ios.md` | Pattern de feature, previews, client généré |
| `93-annexe-captures-e2e.md` | Scénarios de bout en bout, captures, panneaux |
| `TEMPLATE-CLAUDE.md` | Le `CLAUDE.md` d'un projet, sous 80 lignes |
| `TEMPLATE-project-context.md` | Les faits locaux : identifiants, accès, appareils, état |

## Installer sur un projet neuf

1. Copier les fichiers voulus à la racine du projet, dans un dossier `playbook/`. Les étages
   Stack et Annexes ne se copient que si la stack correspond.
2. Copier `TEMPLATE-CLAUDE.md` en `CLAUDE.md` à la racine, remplir les placeholders.
3. Copier `TEMPLATE-project-context.md` en `project-context.md`, le remplir au fil de l'eau.
4. Créer la commande de préflight du projet (`{{PREFLIGHT_COMMAND}}`), celle qui enchaîne linter,
   vérification de types et tests. Sans elle, la moitié des règles de `04-push-protocol.md` ne
   sont que des intentions.

## Les placeholders

| Placeholder | Signification |
|---|---|
| `{{APP_NAME}}` | Nom du projet |
| `{{MAIN_BRANCH}}` | Branche principale |
| `{{BUILD_COMMAND}}` | Commande de build du backend ou de l'application |
| `{{TYPECHECK_COMMAND}}` | Vérification de types |
| `{{TEST_COMMAND}}` | Suite de tests |
| `{{LINT_COMMAND}}` / `{{LINT_FIX_COMMAND}}` | Linter en lecture, puis en écriture |
| `{{PREFLIGHT_COMMAND}}` | Les trois précédentes enchaînées |
| `{{E2E_COMMAND}}` | Scénarios de bout en bout |
| `{{SCREENSHOTS_COMMAND}}` | Régénération des captures |
| `{{RELEASE_TAG_PATTERN}}` | Forme du tag qui déclenche la release |
| `{{SOURCE_LANGUAGE}}` | Langue source du changelog |
| `{{SERVED_LANGUAGES}}` | Langues servies aux utilisateurs |
| `{{REVIEW_LANGUAGE}}` | Langue dont les notes sont validées par l'humain |
| `{{DEVICE_NAME}}` | Appareil de test physique |
| `{{RUNTIME}}` | Gestionnaire de paquets et runtime |

## Règles d'écriture du socle

1. Une règle vit à un seul endroit. Les autres fichiers pointent vers elle.
2. Le socle dit quoi faire et quoi vérifier. Les annexes expliquent la stack.
3. Tout ce qui est spécifique à un projet est un placeholder, repérable d'un grep.
4. Une règle vérifiable devient une commande, pas un rappel.
5. Zéro nom de projet, d'identifiant, de compte ou d'appareil dans ces fichiers.
6. Prose en français, noms de commandes, fichiers et concepts techniques en anglais.
7. Jamais de tiret cadratin ni demi-cadratin, ici comme dans la copy produit.
