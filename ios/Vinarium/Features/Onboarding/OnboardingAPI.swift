import Foundation

/// The signed-in user's onboarding state, read at launch to decide routing.
/// `isAdmin` rides the same query so the admin surfaces cost no extra call.
struct MeState {
    let firstName: String?
    let onboardingCompleted: Bool
    let isAdmin: Bool
}

/// Everything the opening of the app needs, read in one round trip.
struct LaunchState {
    let me: MeState
    let entitlement: EntitlementState
    let quota: QuotaState
}

enum OnboardingAPI {
    static func loadMe() async throws -> MeState {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.MeQuery()
        )
        return meState(data.me.fragments.meFields)
    }

    static func launch() async throws -> LaunchState {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.LaunchQuery()
        )
        return LaunchState(
            me: meState(data.me.fragments.meFields),
            entitlement: SubscriptionAPI.state(data.entitlement.fragments.entitlementFields),
            quota: SubscriptionAPI.quotaState(data.quota.fragments.quotaFields)
        )
    }

    private static func meState(_ me: VinariumGraphQL.MeFields) -> MeState {
        MeState(
            firstName: me.firstName,
            onboardingCompleted: me.onboardingCompleted,
            isAdmin: me.isAdmin
        )
    }

    static func completeOnboarding(firstName: String, rows: Int, cols: Int, zones: Int) async throws {
        let input = VinariumGraphQL.CompleteOnboardingInput(
            cols: Int32(cols),
            firstName: firstName,
            rows: Int32(rows),
            zones: Int32(zones)
        )
        _ = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.CompleteOnboardingMutation(input: input)
        )
    }
}
