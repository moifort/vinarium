# Changelog

## Structure

Un fichier par langue servie : `{{SOURCE_LANGUAGE}}` fait foi, les autres sont ses traductions et
restent en lockstep. Le plus récent en haut.

Chaque version porte son numéro et sa date : `## <version> (<AAAA.MM.JJ>)`. Un `## Unreleased`
sans date est toléré pour du travail en cours, mais il s'affiche littéralement dans l'application
s'il part en release : le renommer fait partie de la release, dans **tous** les fichiers.

Sous une version, trois sous-sections, seulement celles qui ont du contenu : nouveautés,
corrections, performance. Elles servent à organiser le dépôt ; si le parseur qui sert le contenu
les ignore, l'application affiche une liste plate, et c'est très bien.

## Quoi loguer

Uniquement le conséquent, du point de vue de la personne qui utilise le produit. Un libellé
renommé, un sous-titre modifié, un compteur retiré n'ont aucun impact : ils n'y figurent pas.
Aucun jargon technique, aucun nom de fichier, aucun nom de service : l'effet perçu, rien d'autre.

## Quand l'écrire

Au moment de la release, jamais à un push ordinaire. Un push sur la branche principale ne porte
aucune modification de changelog.

L'ordre : écrire les notes dans la langue source, traduire dans chaque langue servie, versionner
les en-têtes partout, faire valider, pousser la branche principale pour que le contenu servi soit
régénéré, puis taguer.

## Validation humaine

Les notes en `{{REVIEW_LANGUAGE}}` sont montrées dans la conversation et validées explicitement
avant tout push. Les corrections demandées sont répercutées dans toutes les autres langues. Pas
de push sur des notes non validées.

## Ton

Voir [08-copywriting.md](08-copywriting.md). Il s'applique intégralement, dans chaque langue.
