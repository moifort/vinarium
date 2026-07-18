import { BeverageType } from '~/domain/beverage/infrastructure/graphql/types'
import { builder } from '~/domain/shared/graphql/builder'
import type { Gift, GiftGiven, GiftReceived } from '../../types'

const GiftGivenType = builder.objectRef<GiftGiven>('GiftGiven').implement({
  description:
    'The given-away facet of a gift: this bottle was handed to someone and has left the cellar.\n\n' +
    'Present when the user gave the wine away. `date` is when it happened; `recipientName` is optional.',
  fields: (t) => ({
    date: t.expose('date', {
      type: 'DateTime',
      description: 'When the bottle was given away.',
    }),
    recipientName: t.expose('recipientName', {
      type: 'PersonName',
      nullable: true,
      description: 'Who the bottle was given to, if recorded.',
    }),
  }),
})

const GiftReceivedType = builder.objectRef<GiftReceived>('GiftReceived').implement({
  description:
    'The received facet of a gift: provenance, recording that this bottle was a gift to the user.\n\n' +
    'Present when the wine was received from someone. It does not affect cellar stock, it only captures where the bottle came from.',
  fields: (t) => ({
    from: t.expose('from', {
      type: 'PersonName',
      description: 'Who gave the bottle to the user.',
    }),
  }),
})

export const GiftType = builder.objectRef<Gift>('Gift').implement({
  description:
    'How a wine relates to gifting, as one record per (user, wine).\n\n' +
    'Data hangs off a `Beverage` and is exposed as the satellite field `Beverage.gift`, resolved through a per-request loader (no N+1).\n\n' +
    'The two facets may coexist: a bottle can be `received` from someone and later `given` away. `given` means the bottle left the cellar; `received` is pure provenance.',
  fields: (t) => ({
    given: t.field({
      type: GiftGivenType,
      nullable: true,
      description: 'Set when the bottle was given away (and thus left the cellar); null otherwise.',
      resolve: (g) => g.given,
    }),
    received: t.field({
      type: GiftReceivedType,
      nullable: true,
      description: 'Set when the bottle was received as a gift (provenance); null otherwise.',
      resolve: (g) => g.received,
    }),
  }),
})

builder.objectField(BeverageType, 'gift', (t) =>
  t.field({
    type: GiftType,
    nullable: true,
    description:
      'Gift facets for this wine (given away and/or received), or null if the bottle has no gift record.',
    resolve: async (wine, _, { loaders }) => (await loaders.gift.load(wine.id)) ?? null,
  }),
)
