import { BeverageType } from '~/domain/beverage/infrastructure/graphql/types'
import { builder } from '~/domain/shared/graphql/builder'
import type { Recommendation } from '../../types'

export const RecommendationType = builder.objectRef<Recommendation>('Recommendation').implement({
  description:
    'A note that someone recommended this wine to the user, as one record per (user, wine).\n\n' +
    'Data hangs off a `Beverage` and is exposed as the satellite field `Beverage.recommendation`, resolved through a per-request loader (no N+1).\n\n' +
    'Captures who suggested the bottle and an optional free-text comment.',
  fields: (t) => ({
    recommenderName: t.expose('recommenderName', {
      type: 'PersonName',
      nullable: true,
      description: 'Who recommended the wine, if recorded.',
    }),
    comment: t.exposeString('comment', {
      nullable: true,
      description: 'Free-text note about the recommendation, if any.',
    }),
  }),
})

builder.objectField(BeverageType, 'recommendation', (t) =>
  t.field({
    type: RecommendationType,
    nullable: true,
    description: 'Recommendation record for this wine, or null if it was never recommended.',
    resolve: async (wine, _, { loaders }) => (await loaders.recommendation.load(wine.id)) ?? null,
  }),
)
