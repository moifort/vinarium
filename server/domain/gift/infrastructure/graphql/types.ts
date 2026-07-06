import { builder } from '~/domain/shared/graphql/builder'
import { WineType } from '~/domain/wine/infrastructure/graphql/types'
import { GiftQuery } from '../../query'
import type { Gift } from '../../types'

export const GiftType = builder.objectRef<Gift>('Gift').implement({
  description: 'Record of a wine that was gifted away',
  fields: (t) => ({
    giftedDate: t.expose('giftedDate', { type: 'DateTime' }),
    recipientName: t.expose('recipientName', { type: 'PersonName', nullable: true }),
  }),
})

builder.objectField(WineType, 'gift', (t) =>
  t.field({
    type: GiftType,
    nullable: true,
    description: 'Gift details for this wine (null if never gifted)',
    resolve: async (wine, _, { userId }) => {
      if (wine.gift !== undefined) return wine.gift
      const gift = await GiftQuery.getByWineId(userId, wine.id)
      return gift === 'not-found' ? null : gift
    },
  }),
)
