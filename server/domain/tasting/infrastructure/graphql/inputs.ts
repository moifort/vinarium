import { builder } from '~/domain/shared/graphql/builder'

export const ShortlistInput = builder.inputType('ShortlistInput', {
  description: 'Tasting fields captured when adding a wine to the shortlist',
  fields: (t) => ({
    consumedDate: t.field({ type: 'DateTime' }),
    rating: t.field({ type: 'Rating' }),
    tastingNotes: t.string(),
    contacts: t.stringList(),
  }),
})
