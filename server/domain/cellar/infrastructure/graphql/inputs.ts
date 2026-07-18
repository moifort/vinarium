import { builder } from '~/domain/shared/graphql/builder'

export const ConsumptionInput = builder.inputType('ConsumptionInput', {
  description:
    'Tasting note recorded when a bottle is consumed out of the cellar.\n\n' +
    'Passed to `consumeBottle`; every field is optional so a bottle can be drunk without any details. Mirrors `TastingInput` from the tasting domain.',
  fields: (t) => ({
    consumedDate: t.field({ type: 'DateTime', description: 'When the bottle was drunk.' }),
    rating: t.field({ type: 'Rating', description: 'Score from 1 to 5.' }),
    tastingNotes: t.string({ description: 'Free-form tasting comment.' }),
    contacts: t.stringList({ description: 'Names of people the bottle was shared with.' }),
    favorite: t.boolean({ description: 'Whether the wine is flagged as a favorite.' }),
  }),
})

export const GiftInput = builder.inputType('GiftInput', {
  description:
    'Details recorded when a bottle leaves the cellar as a gift.\n\n' +
    'Passed to `giftBottle`; `giftedDate` is required, the recipient is optional.',
  fields: (t) => ({
    giftedDate: t.field({
      type: 'DateTime',
      required: true,
      description: 'When the bottle was given away.',
    }),
    recipientName: t.field({ type: 'PersonName', description: 'Who received the bottle.' }),
  }),
})
