import { builder } from '~/domain/shared/graphql/builder'
import type { HouseholdInvitation, HouseholdMember, HouseholdView } from '../../types'
import { HouseholdRoleEnum } from './enums'

export const HouseholdMemberType = builder.objectRef<HouseholdMember>('HouseholdMember').implement({
  description: 'A member of a household',
  fields: (t) => ({
    userId: t.expose('userId', { type: 'UserId' }),
    displayName: t.expose('displayName', { type: 'PersonName' }),
    role: t.field({ type: HouseholdRoleEnum, resolve: (member) => member.role }),
    isMe: t.boolean({
      description: 'Whether this member is the current user',
      resolve: (member, _args, { userId }) => member.userId === userId,
    }),
    joinedAt: t.expose('joinedAt', { type: 'DateTime' }),
  }),
})

export const HouseholdInvitationType = builder
  .objectRef<Pick<HouseholdInvitation, 'code' | 'expiresAt'>>('HouseholdInvitation')
  .implement({
    description: 'An open invitation code to join a household',
    fields: (t) => ({
      code: t.exposeString('code'),
      expiresAt: t.expose('expiresAt', { type: 'DateTime' }),
    }),
  })

export const HouseholdType = builder.objectRef<HouseholdView>('Household').implement({
  description: 'A household: a group of people sharing one physical cellar',
  fields: (t) => ({
    id: t.expose('id', { type: 'HouseholdId' }),
    members: t.field({ type: [HouseholdMemberType], resolve: (household) => household.members }),
    invitations: t.field({
      type: [HouseholdInvitationType],
      description: 'Invitation codes still open, shown so any member can share them',
      resolve: (household) => household.invitations,
    }),
    createdAt: t.expose('createdAt', { type: 'DateTime' }),
  }),
})
