import { builder } from '~/domain/shared/graphql/builder'

export const ConsumptionInput = builder.inputType('ConsumptionInput', {
  description: 'Details captured when consuming a bottle',
  fields: (t) => ({
    consumedDate: t.field({ type: 'DateTime' }),
    rating: t.field({ type: 'Rating' }),
    tastingNotes: t.string(),
    contacts: t.stringList(),
    favorite: t.boolean(),
  }),
})

export const GiftInput = builder.inputType('GiftInput', {
  description: 'Details captured when gifting a bottle',
  fields: (t) => ({
    giftedDate: t.field({ type: 'DateTime', required: true }),
    recipientName: t.field({ type: 'PersonName' }),
  }),
})
