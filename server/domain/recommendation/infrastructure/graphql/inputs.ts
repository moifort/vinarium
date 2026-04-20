import { builder } from '~/domain/shared/graphql/builder'

export const RecommendationInput = builder.inputType('RecommendationInput', {
  description: 'Details captured when recording a recommendation for a wine',
  fields: (t) => ({
    recommenderName: t.field({ type: 'PersonName' }),
    comment: t.string(),
  }),
})
