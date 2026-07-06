import { builder } from '~/domain/shared/graphql/builder'
import { WineType } from '~/domain/wine/infrastructure/graphql/types'
import type { Gift, GiftGiven, GiftReceived } from '../../types'

const GiftGivenType = builder.objectRef<GiftGiven>('GiftGiven').implement({
  description: 'The bottle was given away',
  fields: (t) => ({
    date: t.expose('date', { type: 'DateTime' }),
    recipientName: t.expose('recipientName', { type: 'PersonName', nullable: true }),
  }),
})

const GiftReceivedType = builder.objectRef<GiftReceived>('GiftReceived').implement({
  description: 'The bottle was received as a gift (provenance)',
  fields: (t) => ({
    from: t.expose('from', { type: 'PersonName' }),
  }),
})

export const GiftType = builder.objectRef<Gift>('Gift').implement({
  description: 'How a wine relates to gifting — given away and/or received',
  fields: (t) => ({
    given: t.field({ type: GiftGivenType, nullable: true, resolve: (g) => g.given }),
    received: t.field({ type: GiftReceivedType, nullable: true, resolve: (g) => g.received }),
  }),
})

builder.objectField(WineType, 'gift', (t) =>
  t.field({
    type: GiftType,
    nullable: true,
    description: 'Gift details for this wine (null if never gifted)',
    resolve: async (wine, _, { loaders }) => (await loaders.gift.load(wine.id)) ?? null,
  }),
)
