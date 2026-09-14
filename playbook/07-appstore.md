# Soumission d'une application mobile

Complément de [05-release.md](05-release.md) pour la partie magasin d'applications.

## Toolchain

Construire avec la dernière version **finale** des outils de build, jamais une beta ni une
release candidate, et jamais une version dépassée une fois qu'une plus récente est sortie. Les
deux cas provoquent le même rejet à l'upload, pour SDK non supporté.

Si la machine de build tourne sur un système d'exploitation en beta, l'archive porte une
empreinte de machine prérelease qui déclenche le même rejet. Deux issues : archiver sur une
machine en version finale, ce qui est l'option propre, ou corriger l'empreinte dans l'archive
après le build et avant l'export, l'export re-signant par-dessus. Vérifier alors que les
empreintes d'outils et de SDK, elles, n'ont pas été touchées.

## Signing

Signing manuel de bout en bout, archive comprise : certificat dédié et profil de provisioning
explicites. La clé d'API du magasin sert à téléverser et à soumettre, pas à signer. Noter la date
d'expiration du certificat dans le contexte projet : une expiration non anticipée casse la chaîne
de release sans prévenir, avec une erreur d'authentification illisible.

## Ordre des envois

Les panneaux de captures partent **avant** la soumission : une version déjà en revue refuse les
nouvelles captures.

## Captures

Les captures et les panneaux marketing se régénèrent **localement** et se committent. La CI ne
les produit pas, elle téléverse ce que le dépôt contient : un panneau périmé dans le dépôt est un
panneau périmé dans le magasin.

Quand un écran a changé depuis la dernière release, on régénère toutes les langues, pas
seulement celle qu'on a sous les yeux.

Règle de composition : ne jamais faire re-rendre une interface par un modèle d'image. Les textes
d'interface en ressortent déformés, même avec une consigne de fidélité. On génère le décor avec
des zones réservées et on compose les vraies captures par-dessus. Voir
[93-annexe-captures-e2e.md](93-annexe-captures-e2e.md).

## Métadonnées

La fiche du magasin, ses traductions et ses réponses de confidentialité vivent dans le dépôt, pas
seulement dans la console. Ce qui n'est écrit que dans une console se perd à la première
migration de compte.
