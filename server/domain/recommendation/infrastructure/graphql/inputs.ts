import { builder } from '~/domain/shared/graphql/builder'

export const RecommendationInput = builder.inputType('RecommendationInput', {
  description:
    'Fields captured when recording that someone recommended a wine.\n\n' +
    'Both fields are optional: a recommendation can be saved with just a name, just a comment, or both.',
  fields: (t) => ({
    recommenderName: t.field({
      type: 'PersonName',
      description: 'Who recommended the wine.',
    }),
    comment: t.string({ description: 'Free-text note about the recommendation.' }),
  }),
})
