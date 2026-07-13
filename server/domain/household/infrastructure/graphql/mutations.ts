import { match, P } from 'ts-pattern'
import { builder } from '~/domain/shared/graphql/builder'
import { domainError, notFound } from '~/domain/shared/graphql/errors'
import type { UserId } from '~/domain/shared/types'
import { HouseholdCommand } from '../../command'
import { InvitationCode } from '../../primitives'
import { HouseholdQuery } from '../../query'
import { HouseholdInvitationType, HouseholdType } from './types'

// Derived from the commands so the union can never drift from the domain:
// a new outcome literal grows this type and fails the exhaustive match below.
type HouseholdError = Extract<
  | Awaited<ReturnType<typeof HouseholdCommand.joinByCode>>
  | Awaited<ReturnType<typeof HouseholdCommand.leave>>
  | Awaited<ReturnType<typeof HouseholdCommand.removeMember>>
  | Awaited<ReturnType<typeof HouseholdCommand.revokeInvitation>>
  | Awaited<ReturnType<typeof HouseholdQuery.view>>,
  string
>

// Maps each domain error to the GraphQL error code the client branches on.
const householdError = (error: HouseholdError): never =>
  match(error)
    .with('invalid-code', () => domainError('INVALID_CODE', 'invalid code'))
    .with('expired', () => domainError('CODE_EXPIRED', 'expired'))
    .with('already-used', () => domainError('CODE_ALREADY_USED', 'already used'))
    .with('revoked', () => domainError('CODE_REVOKED', 'revoked'))
    .with('already-in-household', () => domainError('ALREADY_IN_HOUSEHOLD', 'already in household'))
    .with('not-in-household', () => notFound('not in household'))
    .with('not-owner', () => domainError('NOT_OWNER', 'not owner'))
    .with('not-a-member', () => notFound('not a member'))
    .with('cannot-remove-self', () => domainError('CANNOT_REMOVE_SELF', 'cannot remove self'))
    .exhaustive()

// Reject a malformed code the same way as an unknown one, rather than surfacing a
// raw validation error.
const parseCode = (raw: string) => {
  try {
    return InvitationCode(raw)
  } catch {
    return householdError('invalid-code')
  }
}

const householdView = async (userId: UserId) =>
  match(await HouseholdQuery.view(userId))
    .with('not-in-household', householdError)
    .with(P.not(P.string), (view) => view)
    .exhaustive()

builder.mutationField('createHouseholdInvitation', (t) =>
  t.field({
    type: HouseholdInvitationType,
    description:
      'Generate an invitation code for the current user’s household, creating the household on first use',
    args: {
      displayName: t.arg({
        type: 'PersonName',
        required: true,
        description: 'Name the inviter is shown as in the household',
      }),
    },
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
      code: t.arg.string({ required: true, description: 'Invitation code to redeem' }),
      displayName: t.arg({
        type: 'PersonName',
        required: true,
        description: 'Name the joining member is shown as',
      }),
    },
    resolve: async (_root, { code, displayName }, { userId }) => {
      const result = await HouseholdCommand.joinByCode(userId, parseCode(code), displayName)
      return match(result)
        .with(P.string, householdError)
        .with({ outcome: 'joined' }, () => householdView(userId))
        .exhaustive()
    },
  }),
)

builder.mutationField('leaveHousehold', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Leave the current household',
    resolve: async (_root, _args, { userId }) => {
      const result = await HouseholdCommand.leave(userId)
      return match(result)
        .with('not-in-household', householdError)
        .with({ outcome: 'left' }, () => true)
        .exhaustive()
    },
  }),
)

builder.mutationField('removeHouseholdMember', (t) =>
  t.field({
    type: HouseholdType,
    description: 'Remove a member from the household (owner only)',
    args: {
      userId: t.arg({ type: 'UserId', required: true, description: 'Member to remove' }),
    },
    resolve: async (_root, args, { userId }) => {
      const result = await HouseholdCommand.removeMember(userId, args.userId)
      return match(result)
        .with(P.string, householdError)
        .with({ outcome: 'removed' }, () => householdView(userId))
        .exhaustive()
    },
  }),
)

builder.mutationField('revokeHouseholdInvitation', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Revoke an open invitation code',
    args: { code: t.arg.string({ required: true, description: 'Invitation code to revoke' }) },
    resolve: async (_root, { code }, { userId }) => {
      const result = await HouseholdCommand.revokeInvitation(userId, parseCode(code))
      return match(result)
        .with(P.string, householdError)
        .with({ outcome: 'revoked' }, () => true)
        .exhaustive()
    },
  }),
)
