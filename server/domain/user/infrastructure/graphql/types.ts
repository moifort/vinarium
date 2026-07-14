import { builder } from '~/domain/shared/graphql/builder'
import type { MeView } from '~/domain/user/types'

export const MeType = builder.objectRef<MeView>('Me').implement({
  description: 'The signed-in user’s profile and onboarding state',
  fields: (t) => ({
    userId: t.expose('userId', { type: 'UserId', description: 'Firebase Auth user id' }),
    firstName: t.expose('firstName', {
      type: 'PersonName',
      nullable: true,
      description: 'The user’s first name, set during onboarding',
    }),
    onboardingCompletedAt: t.expose('onboardingCompletedAt', {
      type: 'DateTime',
      nullable: true,
      description: 'When onboarding was completed, null if it never was',
    }),
    onboardingCompleted: t.boolean({
      description: 'Whether onboarding is done — the flag the app routes on',
      resolve: (me) => me.onboardingCompletedAt != null,
    }),
  }),
})
