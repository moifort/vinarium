import { builder } from '~/domain/shared/graphql/builder'

export const CompleteOnboardingInput = builder.inputType('CompleteOnboardingInput', {
  description: 'The prénom and cellar dimensions collected by the onboarding wizard',
  fields: (t) => ({
    firstName: t.field({
      type: 'PersonName',
      required: true,
      description: 'The user’s first name',
    }),
    rows: t.int({ required: true, description: 'Number of rows, labelled A..Z (1..100)' }),
    cols: t.int({ required: true, description: 'Number of slots per row (1..100)' }),
    zones: t.int({ required: true, description: 'Number of temperature zones (1..3)' }),
  }),
})
