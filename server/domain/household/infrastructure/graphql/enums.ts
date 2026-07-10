import { builder } from '~/domain/shared/graphql/builder'

export const HouseholdRoleEnum = builder.enumType('HouseholdRole', {
  description: 'A member’s role within their household',
  values: {
    OWNER: { value: 'owner' },
    MEMBER: { value: 'member' },
  } as const,
})
