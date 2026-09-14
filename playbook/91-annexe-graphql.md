# Annexe : schéma et résolveurs

Forme longue de [09-backend.md](09-backend.md) pour la couche d'exposition GraphQL. Domaine
d'exemple neutre : `item` et son satellite `review`.

## Un seul point d'entrée

L'API publique est GraphQL et rien d'autre : un unique `POST /graphql`, plus les routes
d'exploitation. Pas de routes REST par ressource. Le schéma est décrit en code, chaque domaine
apportant ses types, requêtes et mutations depuis son dossier d'infrastructure, tous enregistrés
sur un constructeur partagé et assemblés en un seul endroit.

Le contexte est reconstruit à chaque requête : l'évènement, l'utilisateur authentifié posé par le
middleware, et un jeu de chargeurs neufs. L'absence d'utilisateur se solde par un refus avant même
d'entrer dans le moteur GraphQL.

## Requête de liste

Déléguer au namespace de requête du domaine. Les arguments portent leur valeur par défaut et leur
description, visible dans l'explorateur de schéma.

```ts
builder.queryField('items', (t) =>
  t.field({
    type: ItemsType,
    description: 'A page of the current user’s items, filtered and sorted per view',
    args: {
      sort: t.arg({ type: ItemSortEnum, defaultValue: 'updatedAt', description: 'Order field' }),
      limit: t.arg.int({ defaultValue: 40, description: 'Maximum items returned' }),
      after: t.arg({ type: 'ItemId', description: 'Cursor: the item id to page after' }),
    },
    resolve: async (_root, args, { userId }) =>
      ItemQuery.list(userId, { sort: args.sort ?? 'updatedAt', limit: args.limit ?? 40 }),
  }),
)
```

## Requête unitaire

La nullabilité par défaut est désactivée : un champ qui peut être absent l'annonce. Une issue
`'not-found'` sur une simple consultation se traduit par `null`.

## Mutation

Déléguer à une commande ou à un cas d'usage, puis faire correspondre les issues de façon
exhaustive. La branche de succès reconnaît « ce qui n'est pas une chaîne ». Une suppression
retourne un booléen et reconnaît `undefined`.

## La règle N+1

Les champs satellites greffés sur un type ne doivent jamais parcourir une collection ni lire un
document par ligne parente. Ils passent par un chargeur par requête, qui mémoïse et regroupe les
lectures par identifiant parent.

```ts
builder.objectField(ItemType, 'review', (t) =>
  t.field({
    type: ReviewType,
    nullable: true,
    resolve: (item, _args, { loaders }) => loaders.review.load(item),
  }),
)
```

Une page de 40 lignes qui sélectionne le satellite coûte une lecture groupée, un satellite non
sélectionné ne coûte rien. Cela s'affirme dans les tests fonctionnels, avec les compteurs de
lecture.

## Validation à la frontière

Chaque type brandé a son scalaire, qui valide et brande à l'analyse de la requête. Les résolveurs
reçoivent donc des arguments déjà validés et n'appellent jamais un constructeur eux-mêmes. Une
entrée invalide devient une erreur de saisie avant l'exécution du résolveur.

## Règles

1. Valider au scalaire, jamais dans le domaine.
2. Faire correspondre les issues de façon exhaustive.
3. Les champs imbriqués passent par les chargeurs.
4. Documenter chaque type, champ, énumération et argument.
5. Changement d'abord dans le domaine, ensuite dans le schéma : le domaine est la source de
   vérité.

## Évolution du schéma

Le schéma n'est pas versionné et ne porte pas de cycle de dépréciation. Les clients anciens sont
traités par une porte de mise à jour forcée : le backend publie un numéro de build minimum
supporté, et tout client plus ancien est bloqué au lancement par un écran qui renvoie vers le
magasin.

Compromis assumé : simplicité maximale du code, contre une fenêtre de blocage pendant la revue du
magasin à chaque changement cassant.

| Type de changement | Ce qu'il faut faire |
|---|---|
| Ajout de champ, de requête, de mutation, d'entrée optionnelle | Rien. Les anciens clients continuent de fonctionner |
| Suppression, renommage, entrée plus stricte, valeurs d'énumération changées | Livrer backend et client ensemble, relever le plancher de build, pousser, taguer |

La clé de comparaison est le numéro de build entier, jamais la version commerciale. Le plancher
vise le build de la version sur le point de sortir, en tenant compte du fait que le commit qui
relève le plancher incrémente lui-même le compte.

La porte échoue ouverte : si la configuration est injoignable ou illisible, l'application reste
utilisable. On ne verrouille jamais un utilisateur parce que le contrôle lui-même a échoué.

## Explorateur local

En développement, le point d'entrée sert un explorateur embarqué, et l'authentification a un
contournement réservé au mode développement, éliminé à la construction du bundle. Attention : un
environnement de développement branché sur des données réelles exécute de vraies mutations.
