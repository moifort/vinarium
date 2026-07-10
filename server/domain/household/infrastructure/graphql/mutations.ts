import { GraphQLError } from 'graphql'
import { builder } from '~/domain/shared/graphql/builder'
import type { UserId } from '~/domain/shared/types'
import { HouseholdCommand } from '../../command'
import { InvitationCode } from '../../primitives'
import { HouseholdQuery } from '../../query'
import { HouseholdInvitationType, HouseholdType } from './types'

// Maps each domain error string to the GraphQL error code the client branches on.
const ERROR_CODES: Record<string, string> = {
  'invalid-code': 'INVALID_CODE',
  expired: 'CODE_EXPIRED',
  'already-used': 'CODE_ALREADY_USED',
  revoked: 'CODE_REVOKED',
  'already-in-household': 'ALREADY_IN_HOUSEHOLD',
  'not-in-household': 'NOT_FOUND',
  'not-owner': 'NOT_OWNER',
  'not-a-member': 'NOT_FOUND',
  'cannot-remove-self': 'CANNOT_REMOVE_SELF',
}

const fail = (error: string): never => {
  throw new GraphQLError(error.replace(/-/g, ' '), {
    extensions: { code: ERROR_CODES[error] ?? 'BAD_REQUEST' },
  })
}

// Reject a malformed code the same way as an unknown one, rather than surfacing a
// raw validation error.
const parseCode = (raw: string) => {
  try {
    return InvitationCode(raw)
  } catch {
    return fail('invalid-code')
  }
}

const householdView = async (userId: UserId) => {
  const view = await HouseholdQuery.view(userId)
  if (view === 'not-in-household') return fail('not-in-household')
  return view
}

builder.mutationField('createHouseholdInvitation', (t) =>
  t.field({
    type: HouseholdInvitationType,
    description:
      'Generate an invitation code for the current user’s household, creating the household on first use',
    args: { displayName: t.arg({ type: 'PersonName', required: true }) },
    resolve: async (_root, { displayName }, { userId }) => {
      const result = await HouseholdCommand.createInvitation(userId, displayName)
      return { code: result.code, expiresAt: result.expiresAt }
    },
  }),
)

builder.mutationField('joinHousehold', (t) =>
  t.field({
    type: HouseholdType,
    description: 'Join a household with an invitation code',
    args: {
      code: t.arg.string({ required: true }),
      displayName: t.arg({ type: 'PersonName', required: true }),
    },
    resolve: async (_root, { code, displayName }, { userId }) => {
      const result = await HouseholdCommand.joinByCode(userId, parseCode(code), displayName)
      if (typeof result === 'string') return fail(result)
      return householdView(userId)
    },
  }),
)

builder.mutationField('leaveHousehold', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Leave the current household',
    resolve: async (_root, _args, { userId }) => {
      const result = await HouseholdCommand.leave(userId)
      if (result === 'not-in-household') return fail(result)
      return true
    },
  }),
)

builder.mutationField('removeHouseholdMember', (t) =>
  t.field({
    type: HouseholdType,
    description: 'Remove a member from the household (owner only)',
    args: { userId: t.arg({ type: 'UserId', required: true }) },
    resolve: async (_root, args, { userId }) => {
      const result = await HouseholdCommand.removeMember(userId, args.userId)
      if (typeof result === 'string') return fail(result)
      return householdView(userId)
    },
  }),
)

builder.mutationField('revokeHouseholdInvitation', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Revoke an open invitation code',
    args: { code: t.arg.string({ required: true }) },
    resolve: async (_root, { code }, { userId }) => {
      const result = await HouseholdCommand.revokeInvitation(userId, parseCode(code))
      if (typeof result === 'string') return fail(result)
      return true
    },
  }),
)
