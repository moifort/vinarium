# Workflow d'une tâche

## Le cycle

1. **Cadrage.** Comprendre l'intention avant de coder. Si deux lectures de la demande mènent à
   deux travaux différents, poser la question maintenant, pas à la fin.
2. **Plan écrit** pour tout ce qui dépasse quelques fichiers ou dont l'approche n'est pas
   évidente.
3. **Implémentation.**
4. **Vérification** : `{{PREFLIGHT_COMMAND}}`, plus le build de la plateforme concernée si elle a
   été touchée. Une affirmation de succès sans sortie de commande derrière n'a pas de valeur.
5. **Revue** avant commit, voir [03-code-review.md](03-code-review.md).
6. **Commit**, voir [02-commits.md](02-commits.md).

## Ce que contient un plan

Un plan ne commence jamais par un bloc de code. Il s'ouvre sur une section « en clair » :

- comment ça marche aujourd'hui,
- ce que ça donne après, idéalement un tableau d'exemples avant et après,
- les mécanismes en jeu, expliqués sans jargon,
- ce qui ne bouge pas,
- pourquoi les tâches sont dans cet ordre.

Les blocs de code servent à l'exécution, l'explication sert à la décision. Sans elle, personne ne
peut juger l'approche avant de la lancer.

Chaque tâche du plan se termine par un livrable testable et sa commande de vérification, avec la
sortie attendue.

## Langue des plans et des specs

Prose en français. Tout ce qui atterrira dans le dépôt reste en anglais : code des blocs,
commentaires, noms de tests, messages de commit. Ces documents sont des supports de décision, pas
de la documentation versionnée.

## Compétences et outillage

Avant de commencer, regarder ce qui est réellement installé et invoquer ce qui correspond à la
tâche. Ne jamais citer, imposer ou documenter une compétence sans avoir vérifié qu'elle existe
sur la machine : une directive qui nomme un outil absent est une directive morte, et elle se
propage aux projets suivants.
