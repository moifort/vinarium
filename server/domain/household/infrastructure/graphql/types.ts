import { builder } from '~/domain/shared/graphql/builder'
import type { HouseholdInvitation, HouseholdMember, HouseholdView } from '../../types'
import { HouseholdRoleEnum } from './enums'

export const HouseholdMemberType = builder.objectRef<HouseholdMember>('HouseholdMember').implement({
  description:
    'One person belonging to a household and sharing its cellar.\n\n' +
    'Each member keeps their own display name and a role (owner or member). Their bottles are pooled into the shared cellar scope.',
  fields: (t) => ({
    userId: t.expose('userId', {
      type: 'UserId',
      description: 'The Firebase Auth id of this member.',
    }),
    displayName: t.expose('displayName', {
      type: 'PersonName',
      description: "The member's name as shown to the rest of the household.",
    }),
    role: t.field({
      type: HouseholdRoleEnum,
      description: 'Whether this member owns the household or simply belongs to it.',
      resolve: (member) => member.role,
    }),
    isMe: t.boolean({
      description:
        'True when this member is the signed-in user, so the UI can highlight the current row.',
      resolve: (member, _args, { userId }) => member.userId === userId,
    }),
    joinedAt: t.expose('joinedAt', {
      type: 'DateTime',
      description: 'When this member joined the household.',
    }),
  }),
})

export const HouseholdInvitationType = builder
  .objectRef<Pick<HouseholdInvitation, 'code' | 'expiresAt'>>('HouseholdInvitation')
  .implement({
    description:
      'An open invitation code that lets another person join the household and share its cellar.\n\n' +
      'A code is redeemed once via `joinHousehold`. It stops working after `expiresAt`, once used, or once revoked with `revokeHouseholdInvitation`.',
    fields: (t) => ({
      code: t.exposeString('code', {
        description: 'The code a prospective member enters to join the household.',
      }),
      expiresAt: t.expose('expiresAt', {
        type: 'DateTime',
        description: 'After this instant the code is no longer accepted.',
      }),
    }),
  })

export const HouseholdType = builder.objectRef<HouseholdView>('Household').implement({
  description:
    'A group of people who share one physical cellar.\n\n' +
    'Membership is granted through invitation codes: the first `createHouseholdInvitation` creates the household, and each `joinHousehold` adds a member. Every member sees the same pooled bottles; the owner also manages membership.\n\n' +
    'Returned by `myHousehold` and by the membership mutations. Null when the signed-in user belongs to no household (they then act as a solo cellar of one).\n\n' +
    '```graphql\n' +
    'query {\n' +
    '  myHousehold {\n' +
    '    id\n' +
    '    members { displayName role isMe }\n' +
    '    invitations { code expiresAt }\n' +
    '  }\n' +
    '}\n' +
    '```',
  fields: (t) => ({
    id: t.expose('id', {
      type: 'HouseholdId',
      description: 'Stable identifier of the household.',
    }),
    members: t.field({
      type: [HouseholdMemberType],
      description: 'Everyone currently in the household, including the signed-in user.',
      resolve: (household) => household.members,
    }),
    invitations: t.field({
      type: [HouseholdInvitationType],
      description: 'Invitation codes still open, shown so any member can share them.',
      resolve: (household) => household.invitations,
    }),
    createdAt: t.expose('createdAt', {
      type: 'DateTime',
      description: 'When the household was first created.',
    }),
  }),
})
