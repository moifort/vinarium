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
      "Generate an open invitation code for the signed-in user's household.\n\n" +
      'The first call creates the household (the caller becomes its owner) and starts the sharing flow. Others redeem the returned code with `joinHousehold`; codes expire, and the owner can revoke them with `revokeHouseholdInvitation`.',
    args: {
      displayName: t.arg({
        type: 'PersonName',
        required: true,
        description: 'The name the inviter is shown as inside the household.',
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
    description:
      'Redeem an invitation code to join its household and share the one cellar.\n\n' +
      'On success the caller becomes a member and gets pooled access to the shared bottles; the updated household is returned. Fails when the code is invalid, expired, already used, revoked, or the user is already in a household.',
    args: {
      code: t.arg.string({
        required: true,
        description: 'The invitation code to redeem, as issued by createHouseholdInvitation.',
      }),
      displayName: t.arg({
        type: 'PersonName',
        required: true,
        description: 'The name the joining member is shown as inside the household.',
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
    description:
      'Leave the household the signed-in user belongs to.\n\n' +
      'The user loses shared access and reverts to a solo cellar of their own bottles. Returns true on success; fails when the user is in no household.',
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
    description:
      'Remove another member from the household. Owner only.\n\n' +
      'The removed member loses shared access and returns to a solo cellar; the updated household is returned. Fails when the caller is not the owner, the target is not a member, or the owner targets themselves (use leaveHousehold instead).',
    args: {
      userId: t.arg({
        type: 'UserId',
        required: true,
        description: 'The member to remove from the household.',
      }),
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
    description:
      'Revoke an open invitation code so it can no longer be redeemed.\n\n' +
      'Used to cancel a code shared by mistake before anyone joins with it. Returns true on success; fails when the caller is not the owner or the code is invalid.',
    args: {
      code: t.arg.string({
        required: true,
        description: 'The still-open invitation code to invalidate.',
      }),
    },
    resolve: async (_root, { code }, { userId }) => {
      const result = await HouseholdCommand.revokeInvitation(userId, parseCode(code))
      return match(result)
        .with(P.string, householdError)
        .with({ outcome: 'revoked' }, () => true)
        .exhaustive()
    },
  }),
)
