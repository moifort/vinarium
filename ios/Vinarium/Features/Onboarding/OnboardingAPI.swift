import Foundation

/// The signed-in user's onboarding state, read at launch to decide routing.
struct MeState {
    let firstName: String?
    let onboardingCompleted: Bool
}

enum OnboardingAPI {
    static func loadMe() async throws -> MeState {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.MeQuery()
        )
        return MeState(
            firstName: data.me.firstName,
            onboardingCompleted: data.me.onboardingCompleted
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
