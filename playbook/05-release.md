# Release

## Le tag est le déclencheur

Une release se déclenche en posant et poussant un tag `{{RELEASE_TAG_PATTERN}}`. Le tag fait
tout : tests de bout en bout, build, publication, soumission.

Quand une release est décidée, le tag se pose immédiatement. On ne le retient pas en attendant
des conditions extérieures : panne du fournisseur de CI, pipeline rouge, doute sur le
déclenchement. Poser un tag ne coûte rien, un run manquant se relance à la main, alors qu'un tag
non posé bloque la chaîne et oblige à revenir demander.

## L'ordre

1. Notes de release écrites et validées, voir [06-changelog.md](06-changelog.md).
2. Push de la branche principale : c'est lui qui déploie le backend et régénère les contenus
   servis. Sans ce push, les notes n'atteignent pas l'application.
3. Artefacts visuels régénérés localement et committés, voir
   [07-appstore.md](07-appstore.md).
4. Tag posé et poussé.

## Le gate

Les scénarios de bout en bout passent en premier et conditionnent la suite : pas de build ni de
publication si un parcours utilisateur est cassé. Ils se lancent aussi en local
(`{{E2E_COMMAND}}`) sur une pile jetable, sans jamais toucher la production.

Un seul run à la fois : ces suites réservent des ports et un simulateur, deux exécutions
concurrentes se sabotent. On ne les lance pas pendant qu'on édite le serveur, qui se reconstruit
en continu.

Pour éprouver la chaîne avant de taguer, lancer le workflow de release à la main dans son mode
« tests seuls ».

## Versionnement

Manuel et explicite : la version portée par le tag est celle écrite dans les notes. Le numéro de
build se dérive du nombre de commits, il ne se bump pas à la main.

## Pipeline rouge sur un tag déjà posé

Le gate se déclenche sur un tag qui existe déjà. Un scénario rouge se corrige, puis on re-tague.
On ne rattrape pas une release en désactivant le gate.
