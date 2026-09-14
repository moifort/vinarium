# Commits

## Format

Commits conventionnels : `type(scope): sujet à l'impératif`, en anglais, minuscule, sans point
final. Types usuels : `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `ci`.

Le scope se déduit du chemin des fichiers touchés, pas d'une taxonomie inventée. Si un commit a
besoin de deux scopes, c'est probablement deux commits.

Le corps sert à expliquer le pourquoi quand il n'est pas évident. Il ne paraphrase pas le diff.

## Granularité

Grouper les changements en commits cohérents, et décider seul de ce regroupement. On ne demande
pas comment découper.

## Branche

Travail direct sur `{{MAIN_BRANCH}}`. Pas de branche de feature ni de pull request sauf demande
explicite.

## Quand committer

Dès qu'une tâche est terminée et que la vérification passe. Sans demander l'autorisation, ni
avant, ni après.

## Quand pousser

Jamais de sa propre initiative. Les commits s'accumulent en local jusqu'à ce qu'on demande
explicitement un push, et alors seulement la check-list de
[04-push-protocol.md](04-push-protocol.md) s'applique.
