import { builder } from '~/domain/shared/graphql/builder'

export const SearchMatchedFieldEnum = builder.enumType('SearchMatchedField', {
  description: 'Which wine field a search query matched — the client groups results by it',
  values: {
    NAME: { value: 'name' },
    PRODUCER: { value: 'producer' },
    SUBTYPE: { value: 'subtype' },
    APPELLATION: { value: 'appellation' },
    REGION: { value: 'region' },
    VINTAGE: { value: 'vintage' },
    GIFTED_BY: { value: 'gifted-by' },
    GIFT_RECIPIENT: { value: 'gift-recipient' },
    RECOMMENDER: { value: 'recommender' },
    TASTING_CONTACT: { value: 'tasting-contact' },
  } as const,
})
