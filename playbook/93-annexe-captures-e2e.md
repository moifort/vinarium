# Annexe : scénarios de bout en bout et captures

Forme longue de [05-release.md](05-release.md) et [07-appstore.md](07-appstore.md).

## Les scénarios de bout en bout

Un petit nombre de parcours utilisateur, rejoués contre le produit entier avant chaque release :
la vraie application sur un simulateur, le vrai backend, des émulateurs à la place des services
de stockage et d'identité.

```
émulateurs (identité, stockage)     seule source de données et d'identité
  └─ serveur applicatif local        le vrai backend, services externes bouchonnés
       └─ simulateur                 la vraie application, pilotée par les tests d'interface
```

Rien n'atteint la production. Les émulateurs démarrent vides et sont jetés à la fin : pas de
route de remise à zéro à maintenir, pas de compte de test à gérer dans le projet cloud, pas de
quota consommé chez un fournisseur payant.

Chaque test s'authentifie avec un compte à lui, ce qui remplace toute notion de remise à zéro
partagée.

### Choisir les scénarios

Un parcours principal qui traverse l'application de bout en bout, puis un parcours par
fonctionnalité structurante qui diverge du principal. Ensemble, ils doivent toucher la majorité
des domaines. Ce qui reste hors de portée, typiquement l'authentification par un fournisseur
tiers, les achats intégrés et les appels à un modèle payant, est listé explicitement comme
vérification manuelle avant release.

### Contraintes d'exécution

- Un seul run à la fois : les ports et le simulateur sont des ressources uniques, deux runs
  concurrents se sabotent, et un run précédent qui s'éteint fait échouer le suivant.
- Ne pas lancer pendant qu'on édite le serveur : il se reconstruit en continu.
- Ne jamais désactiver la signature de code sur une exécution de tests : sans droits d'accès, le
  trousseau refuse et l'authentification échoue avec une erreur illisible.
- Attendre un identifiant d'accessibilité qui n'apparaît qu'une fois l'écran servi, jamais une
  pause fixe.

## Les captures

Les captures servent deux usages : la documentation du dépôt et les panneaux du magasin. Elles
sont produites sur une pile locale, sur un jeu de données semé pour l'occasion, dans toutes les
langues servies.

Limite connue et acceptée : une donnée d'historique semée par l'API publique porte la date du
jour où le semis a tourné. L'étaler demanderait de fabriquer des charges utiles internes à la
main, ce qui coûte plus que le gain.

## Les panneaux du magasin

Un panorama est une image unique découpée en panneaux à la taille attendue par le magasin, avec
un décor qui se poursuit d'un panneau au suivant. Choisir la taille d'écran de référence pour
qu'une capture n'ait jamais à être redimensionnée.

Trois choses sont tenues à l'écart du modèle d'image, délibérément :

- **L'interface de l'application.** Le modèle produit du texte plausible mais faux. On compose les
  vraies captures par-dessus.
- **Les légendes.** Même raison, multipliée par le nombre de langues. Elles sont dessinées par le
  compositeur, dans la police système de chaque langue, avec repli et ajustement pour qu'un mot
  composé long et une ligne idéographique tiennent la même mise en page.
- **L'appareil.** Demandé à une taille donnée, le modèle en rend une différente à chaque essai et
  d'un panneau à l'autre. C'est la seule chose qui ne peut pas varier, puisque les panneaux se
  lisent côte à côte. Le compositeur le dessine, au même emplacement sur chaque panneau.

Les décors générés sont mis en cache et committés : ajouter une langue ou reformuler une légende
ne coûte alors plus rien et ne demande aucune clé d'API. Seule une régénération explicite appelle
le modèle.

Piège d'outillage classique : un recadrage dont l'offset nul est ignoré et recadre au centre. Le
contourner par un offset d'un pixel plutôt que par un pipeline entier.

## L'envoi

Le tag de release envoie les panneaux une fois le binaire téléversé et avant la soumission de la
version. L'ordre n'est pas négociable : une version déjà en revue refuse de nouvelles captures.

C'est pourquoi les panneaux sont committés, poids compris : la CI téléverse ce que le dépôt
contient. Les capturer sur le runner reviendrait à démarrer émulateurs, backend et simulateur
pour toutes les langues, une demi-heure ajoutée à chaque release pour des images qui n'ont pas
changé.
