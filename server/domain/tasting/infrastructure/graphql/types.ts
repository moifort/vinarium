import { builder } from '~/domain/shared/graphql/builder'
import { WineType } from '~/domain/wine/infrastructure/graphql/types'
import { TastingQuery } from '../../query'
import type { TastingNote } from '../../types'

export const ConsumptionType = builder.objectRef<TastingNote>('Consumption').implement({
  description: 'Tasting note / consumption record for a wine',
  fields: (t) => ({
    consumedDate: t.expose('consumedDate', { type: 'DateTime', nullable: true }),
    rating: t.expose('rating', { type: 'Rating', nullable: true }),
    tastingNotes: t.exposeString('tastingNotes', { nullable: true }),
    contacts: t.exposeStringList('contacts', { nullable: true }),
    favorite: t.exposeBoolean('favorite', { nullable: true }),
  }),
})

builder.objectField(WineType, 'consumption', (t) =>
  t.field({
    type: ConsumptionType,
    nullable: true,
    description: 'Tasting / consumption details for this wine (null if never recorded)',
    resolve: async (wine, _, { userId }) => {
      if (wine.consumption !== undefined) return wine.consumption
      const tastings = await TastingQuery.getAll(userId)
      return tastings.find((tasting) => tasting.wineId === wine.id) ?? null
    },
  }),
)
