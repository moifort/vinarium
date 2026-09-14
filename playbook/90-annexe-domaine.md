# Annexe : créer un domaine

Forme longue de [09-backend.md](09-backend.md). Les exemples utilisent un domaine neutre,
`review`, qui attache une note et un commentaire à un objet possédé par un utilisateur.

## Arborescence

```
server/domain/review/
├── types.ts
├── primitives.ts
├── command.ts
├── query.ts
├── business-rules.ts        (optionnel, fonctions pures)
├── use-case.ts              (optionnel, orchestration multi-domaines)
└── infrastructure/
    ├── repository.ts
    └── graphql/
        ├── types.ts
        ├── queries.ts
        ├── mutations.ts
        └── inputs.ts
```

## 1. Les types

Le fichier de types EST la spécification du modèle. Objets-valeur définis par leur valeur,
entités porteuses d'un identifiant.

```ts
import type { Brand } from 'ts-brand'
import type { ItemId } from '~/domain/item/types'
import type { UserId } from '~/domain/shared/types'

export type Rating = Brand<number, 'Rating'>

export type Review = {
  userId: UserId
  itemId: ItemId
  rating?: Rating
  createdAt: Date
}
```

## 2. Les primitives

Rendre les états illégaux non représentables : si une valeur passe le constructeur, elle est
valide partout en aval, et personne ne revalide.

```ts
import { make } from 'ts-brand'
import { z } from 'zod'
import type { Rating as RatingType } from '~/domain/review/types'

export const Rating = (value: unknown) => {
  const v = z.number().int().min(1).max(5).parse(value)
  return make<RatingType>()(v)
}
```

Les unions de littéraux se valident ici aussi, par `z.enum(...)`. Jamais de `as MonType` sur une
entrée non fiable : toujours le constructeur.

Le brand est une fiction du compilateur. À l'exécution, la valeur reste un nombre ou une chaîne :
on ne l'enveloppe jamais dans `String()` ou `Number()`, et elle s'utilise directement en
arithmétique.

Les brands génériques (identifiant d'utilisateur, montant, année, pourcentage) vivent dans le
domaine partagé. Les brands propres à un domaine vivent chez lui.

## 3. Le repository

Interface façon collection au-dessus du stockage, privée au domaine, faite de fonctions exportées
nues, pas d'un namespace.

```ts
const reviews = () => db().collection('review').withConverter(genericDataConverter<Review>())

const docId = (userId: UserId, itemId: ItemId) => `${userId}_${itemId}`

export const findAllByUser = (userId: UserId): Promise<Review[]> =>
  memoizedPerRequest(`review:all:${userId}`, async () => {
    const snap = await reviews().where('userId', '==', userId).get()
    return snap.docs.map((doc) => doc.data())
  })

export const findBy = async (userId: UserId, itemId: ItemId) =>
  (await reviews().doc(docId(userId, itemId)).get()).data() ?? null

export const save = async (review: Review) => {
  await reviews().doc(docId(review.userId, review.itemId)).set(review)
  return review
}
```

Les scans coûteux passent par la mémoïsation par requête. Les écritures multiples passent par un
lot unique, les suppressions massives par lots successifs.

## 4. La requête

Interface publique de lecture du domaine. Les autres domaines passent par elle, jamais par le
repository.

```ts
export namespace ReviewQuery {
  export const all = async (userId: UserId) => repository.findAllByUser(userId)

  export const byId = async (userId: UserId, itemId: ItemId) => {
    const review = await repository.findBy(userId, itemId)
    if (!review) return 'not-found' as const
    return review
  }
}
```

## 5. La commande

Interface publique d'écriture. Chaque issue attendue est une voie explicite, exprimée par une
chaîne littérale.

```ts
export namespace ReviewCommand {
  export const rate = async (userId: UserId, itemId: ItemId, rating: Rating) => {
    const existing = await repository.findBy(userId, itemId)
    const review: Review = { ...(existing ?? { userId, itemId, createdAt: new Date() }), rating }
    return await repository.save(review)
  }
}
```

Règles : `as const` sur les retours littéraux, un discriminant distinct par échec, aucune
exception pour un échec attendu, et succès qui retourne la valeur du domaine ou `undefined`.

## 6. Gestion d'erreur

Les issues sont rares et métier. Le partage succès/échec se lit en `typeof result === 'string'`.

La couche d'exposition fait correspondre chaque issue, de façon exhaustive, via un `match()` qui
échoue à la compilation si une issue nouvelle n'est pas traitée. Jamais de `switch`.

```ts
return match(result)
  .with('not-found', () => notFound('Review not found'))
  .with('rating-out-of-range', () => badUserInput('Rating must be between 1 and 5'))
  .with(P.not(P.string), (review) => review)
  .exhaustive()
```

Trois niveaux : le domaine retourne des issues et lève pour un état impossible, l'exposition fait
correspondre, le framework capture ce qui remonte et alerte.

Règle de partage : si l'appelant ne peut rien faire de l'absence, c'est un état incohérent, on
lève. Si l'absence est un scénario normal déclenché par l'utilisateur, on retourne `'not-found'`.

## 7. Cas d'usage et règles métier

Un cas d'usage orchestre plusieurs domaines sans porter de logique métier. Son nom dit l'intention
métier, jamais `handleX` ni `processX`. Il passe par les commandes et requêtes, la seule exception
étant l'enrôlement dans un lot atomique pour une suppression multi-domaines.

Les règles métier sont des fonctions pures, sans entrée-sortie, sans asynchrone, nommées par le
concept qu'elles calculent. Couverture de test complète attendue.

## 8. Tests

Co-localisés avec le fichier testé, pas de dossier séparé.

| Suffixe | Portée |
|---|---|
| `*.unit.test.ts` | Primitives et fonctions pures |
| `*.int.test.ts` | Commandes et requêtes contre un stockage simulé |
| `*.feat.test.ts` | Scénarios métier à la frontière de l'API |

Le stockage se simule par substitution du module, de sorte que l'ordre des fichiers n'ait pas
d'importance. Les budgets de lecture s'affirment en comptant séparément les lectures de documents
et de requêtes.

## Check-list

- [ ] Types brandés et unions discriminées
- [ ] Constructeurs validants
- [ ] Repository privé, fonctions nues
- [ ] Namespaces de requête et de commande
- [ ] Couche d'exposition enregistrée dans le schéma
- [ ] Un scalaire par nouveau type brandé
- [ ] Tests aux trois niveaux, budgets de lecture affirmés
- [ ] Schéma et client typé régénérés
- [ ] Vérification de types verte
