import { BeverageType } from '~/domain/beverage/infrastructure/graphql/types'
import { builder } from '~/domain/shared/graphql/builder'
import type { TastingNote } from '../../types'

export const ConsumptionType = builder.objectRef<TastingNote>('Consumption').implement({
  description:
    'The tasting note and consumption record kept for a wine.\n\n' +
    'Holds the drinker rating (1 to 5), free-form notes, sharing contacts, the favorite flag, and when the bottle was consumed. Every field is optional: a wine can be a favorite with no rating, or rated with no notes. Exposed as `Beverage.consumption`.',
  fields: (t) => ({
    consumedDate: t.expose('consumedDate', {
      type: 'DateTime',
      nullable: true,
      description: 'When the bottle was drunk; null if not consumed yet.',
    }),
    rating: t.expose('rating', {
      type: 'Rating',
      nullable: true,
      description: 'Drinker score from 1 to 5; null if unrated.',
    }),
    tastingNotes: t.exposeString('tastingNotes', {
      nullable: true,
      description: 'Free-form tasting comment; null if none.',
    }),
    contacts: t.exposeStringList('contacts', {
      nullable: true,
      description: 'Names of people the bottle was shared with.',
    }),
    favorite: t.exposeBoolean('favorite', {
      nullable: true,
      description: 'Whether the wine is flagged as a favorite (heart).',
    }),
  }),
})

builder.objectField(BeverageType, 'consumption', (t) =>
  t.field({
    type: ConsumptionType,
    nullable: true,
    description:
      "The wine's tasting note and consumption record.\n\n" +
      'Exposed as `Beverage.consumption`; null when nothing has ever been recorded for the wine. Resolved through a per-request loader (no N+1).',
    resolve: async (wine, _, { loaders }) => (await loaders.consumption.load(wine.id)) ?? null,
  }),
)
