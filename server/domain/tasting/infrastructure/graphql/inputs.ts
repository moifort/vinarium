import { builder } from '~/domain/shared/graphql/builder'

export const TastingInput = builder.inputType('TastingInput', {
  description:
    'Fields captured when recording a tasting note for a wine.\n\n' +
    'Passed to `recordTasting`; every field is optional, so a note can be just a rating or just a favorite flag. Mirrors `ConsumptionInput` from the cellar domain.',
  fields: (t) => ({
    consumedDate: t.field({ type: 'DateTime', description: 'When the wine was tasted.' }),
    rating: t.field({ type: 'Rating', description: 'Score from 1 to 5.' }),
    tastingNotes: t.string({ description: 'Free-form tasting comment.' }),
    contacts: t.stringList({ description: 'Names of people the wine was shared with.' }),
    favorite: t.boolean({ description: 'Whether the wine is flagged as a favorite.' }),
  }),
})
