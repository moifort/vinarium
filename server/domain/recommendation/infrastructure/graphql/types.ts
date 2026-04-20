import { builder } from '~/domain/shared/graphql/builder'
import { WineType } from '~/domain/wine/infrastructure/graphql/types'
import { RecommendationQuery } from '../../query'
import type { Recommendation } from '../../types'

export const RecommendationType = builder.objectRef<Recommendation>('Recommendation').implement({
  description: 'Record of a wine that was recommended by someone',
  fields: (t) => ({
    recommenderName: t.expose('recommenderName', { type: 'PersonName', nullable: true }),
    comment: t.exposeString('comment', { nullable: true }),
  }),
})

builder.objectField(WineType, 'recommendation', (t) =>
  t.field({
    type: RecommendationType,
    nullable: true,
    description: 'Recommendation details for this wine (null if never recommended)',
    resolve: async (wine, _, { userId }) => {
      const rec = await RecommendationQuery.getByWineId(userId, wine.id)
      return rec === 'not-found' ? null : rec
    },
  }),
)
