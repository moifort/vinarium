import { builder } from '~/domain/shared/graphql/builder'

export const CompleteOnboardingInput = builder.inputType('CompleteOnboardingInput', {
  description:
    'The first name and cellar dimensions collected by the onboarding wizard.\n\n' +
    'Persisted in one step by `completeOnboarding`: it writes the profile and provisions the cellar grid.',
  fields: (t) => ({
    firstName: t.field({
      type: 'PersonName',
      required: true,
      description: "The user's first name.",
    }),
    rows: t.int({ required: true, description: 'Number of rows, labelled A..Z (1..100).' }),
    cols: t.int({ required: true, description: 'Number of slots per row (1..100).' }),
    zones: t.int({ required: true, description: 'Number of temperature zones (1..3).' }),
  }),
})
