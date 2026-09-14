# Revue de code

Chaque tâche terminée passe en revue avant son commit. La revue se fait inline, dans la
conversation courante, sans déléguer à un agent, conformément à
[00-collaboration.md](00-collaboration.md).

## Comment

1. Relire le diff complet (`git diff`, ou `git diff --staged`), pas le souvenir de ce qu'on a
   voulu écrire.
2. Le passer à la grille ci-dessous, point par point.
3. Corriger ce qui doit l'être, puis committer.

## La grille

| Axe | Ce qu'on cherche |
|---|---|
| Correction | Le code fait-il ce que la tâche demandait, entièrement, et rien de plus |
| Cas limites | Vide, absent, zéro, doublon, concurrence, échec réseau, données partielles |
| Sécurité | Entrées non validées à la frontière, secrets en clair, données d'un utilisateur accessibles à un autre |
| Coût | Lectures en boucle, requête par ligne, travail refait à chaque appel |
| Cohérence | Conventions du projet respectées : nommage, structure, gestion d'erreur, style |
| Dette | Duplication introduite, abstraction prématurée, code mort laissé derrière |
| Tests | Un test échouerait-il si la régression revenait |
| Documentation | Une surface visible par l'utilisateur a changé sans que la documentation suive |

## Recevoir une critique

Une remarque de revue n'est ni un ordre ni une vérité. On la vérifie dans le code avant de
l'appliquer. Si elle est juste, on corrige sans commenter longuement. Si elle est fausse, on le
dit avec le fait qui le prouve. Acquiescer à une remarque erronée coûte plus cher que la
contredire.
