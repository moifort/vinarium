import { BeverageType } from '~/domain/beverage/infrastructure/graphql/types'
import { builder } from '~/domain/shared/graphql/builder'
import type { Recommendation } from '../../types'

export const RecommendationType = builder.objectRef<Recommendation>('Recommendation').implement({
  description: 'Record of a wine that was recommended by someone',
  fields: (t) => ({
    recommenderName: t.expose('recommenderName', { type: 'PersonName', nullable: true }),
    comment: t.exposeString('comment', { nullable: true }),
  }),
})

builder.objectField(BeverageType, 'recommendation', (t) =>
  t.field({
    type: RecommendationType,
    nullable: true,
    description: 'Recommendation details for this wine (null if never recommended)',
    resolve: async (wine, _, { loaders }) => (await loaders.recommendation.load(wine.id)) ?? null,
  }),
)
