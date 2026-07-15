import Foundation

enum HouseholdAPI {
    static func myHousehold() async throws -> Household? {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.MyHouseholdQuery()
        )
        guard let household = data.myHousehold else { return nil }
        return map(household.fragments.householdFields)
    }

    static func createInvitation(displayName: String) async throws -> HouseholdInvite {
        let data = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.CreateHouseholdInvitationMutation(displayName: displayName)
        )
        let invite = data.createHouseholdInvitation
        return HouseholdInvite(code: invite.code, expiresAt: GraphQLHelpers.parseISO8601(invite.expiresAt))
    }

    static func join(code: String, displayName: String) async throws -> Household {
        let data = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.JoinHouseholdMutation(code: code, displayName: displayName)
        )
        return map(data.joinHousehold.fragments.householdFields)
    }

    static func removeMember(userId: String) async throws -> Household {
        let data = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.RemoveHouseholdMemberMutation(userId: userId)
        )
        return map(data.removeHouseholdMember.fragments.householdFields)
    }

    static func revokeInvitation(code: String) async throws {
        _ = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.RevokeHouseholdInvitationMutation(code: code)
        )
    }

    private static func map(_ fields: VinariumGraphQL.HouseholdFields) -> Household {
        Household(
            members: fields.members.map { member in
                HouseholdMember(
                    userId: member.userId,
                    displayName: member.displayName,
                    isOwner: member.role == .case(.owner),
                    isMe: member.isMe
                )
            },
            invitations: fields.invitations.map { invite in
                HouseholdInvite(
                    code: invite.code,
                    expiresAt: GraphQLHelpers.parseISO8601(invite.expiresAt)
                )
            }
        )
    }
}
