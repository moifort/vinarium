# Protocole de push

Le push ne part jamais de soi-même. Quand il est demandé, cette check-list s'applique dans
l'ordre, puis on pousse, puis on vérifie.

## Avant

1. **Documentation utilisateur.** Si le travail poussé change la liste des fonctionnalités ou la
   stack, le README suit.
2. **Artefacts visuels.** Si une interface visible a changé, régénérer les captures
   (`{{SCREENSHOTS_COMMAND}}`) et committer le résultat. Un artefact périmé dans le dépôt est un
   artefact périmé en production : la CI ne le régénère pas, elle téléverse ce qu'elle trouve.
3. **Code généré.** Si un contrat d'API a bougé, relancer la génération et committer les fichiers
   produits, pour que les clients typés restent en phase avec ce qui est déployé.
4. **Linter en écriture.** `{{LINT_FIX_COMMAND}}`, puis committer ce qu'il corrige. La CI n'est
   pas un linter : une erreur de lint ne doit jamais se découvrir dans un pipeline rouge.
5. **Préflight.** `{{PREFLIGHT_COMMAND}}` vert.

## Ce que le linter ne doit jamais toucher

Le format d'un artefact généré appartient à son générateur, pas au linter. Quand le linter se
plaint d'un fichier produit par un outil (schéma exporté, asset compilé, icône générée), la
réponse est de l'exclure de la configuration du linter, jamais de le laisser le reformater :
sinon le générateur et le linter se le disputent à chaque exécution, et la CI casse une fois sur
deux.

Réflexe : tout artefact généré ajouté au dépôt est exclu du linter dans le même commit.

## Le changelog ne bouge pas

Un push ordinaire ne touche à aucun fichier de changelog. Le changelog s'écrit au moment de la
release, voir [06-changelog.md](06-changelog.md).

## Après

Le push n'est pas terminé tant que l'état des pipelines n'a pas été observé.

```bash
gh run list --branch {{MAIN_BRANCH}} --limit 5
gh run watch <id>
gh run view <id> --log-failed
```

Tout échec est signalé sans attendre qu'on le demande, avec la cause, pas seulement le nom du job
rouge.
