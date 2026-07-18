import { builder } from '~/domain/shared/graphql/builder'

export const HouseholdRoleEnum = builder.enumType('HouseholdRole', {
  description:
    "A member's role within their household.\n\n" +
    'Governs who may manage membership: only an owner can remove members or revoke invitation codes.',
  values: {
    OWNER: {
      value: 'owner',
      description:
        'The member who created the household. Can invite, remove other members, and revoke codes.',
    },
    MEMBER: {
      value: 'member',
      description:
        'A member who joined via an invitation code. Shares the cellar but cannot manage membership.',
    },
  } as const,
})
