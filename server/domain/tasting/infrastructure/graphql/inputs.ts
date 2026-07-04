import { builder } from '~/domain/shared/graphql/builder'

export const TastingInput = builder.inputType('TastingInput', {
  description: 'Tasting fields captured when recording a tasting note',
  fields: (t) => ({
    consumedDate: t.field({ type: 'DateTime' }),
    rating: t.field({ type: 'Rating' }),
    tastingNotes: t.string(),
    contacts: t.stringList(),
    favorite: t.boolean(),
  }),
})
