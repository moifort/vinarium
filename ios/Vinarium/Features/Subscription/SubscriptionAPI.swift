import Apollo
import Foundation

/// What the server says the account is entitled to. `appAccountToken` is the UUID
/// a purchase must carry to be recognised — the app never derives it, it asks.
struct EntitlementState: Sendable {
    let isPremium: Bool
    let appAccountToken: UUID?
    let productId: String?
    let expiresOn: Date?
}

/// The scan allowance, as the server counts it: the month on one side, the scans
/// granted at onboarding on the other, and what the two add up to.
struct QuotaState: Sendable {
    let isPremium: Bool
    let used: Int
    let limit: Int
    /// What is left of the month alone — the granted scans are not in it.
    let remaining: Int
    /// Granted once, drawn down only after the month, never refilled.
    let welcomeRemaining: Int
    /// Everything that can still be scanned. The number a screen should show.
    let totalRemaining: Int
    let renewsOn: Date?
}

enum SubscriptionAPI {
    /// The plan and the allowance, read in one round trip.
    static func load() async throws -> (EntitlementState, QuotaState) {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.SubscriptionStateQuery()
        )
        return (
            state(data.entitlement.fragments.entitlementFields),
            quotaState(data.quota.fragments.quotaFields)
        )
    }

    static func quota() async throws -> QuotaState {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.QuotaQuery()
        )
        return quotaState(data.quota.fragments.quotaFields)
    }

    /// Hand a transaction the App Store signed to the server, which verifies it
    /// and grants Premium. The only path to Premium there is.
    static func sync(signedTransaction: String) async throws -> EntitlementState {
        let data = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.SyncEntitlementMutation(signedTransaction: signedTransaction)
        )
        return state(data.syncEntitlement.fragments.entitlementFields)
    }

    static func state(_ entitlement: VinariumGraphQL.EntitlementFields) -> EntitlementState {
        EntitlementState(
            isPremium: entitlement.plan.value == .premium,
            appAccountToken: UUID(uuidString: entitlement.appAccountToken),
            productId: entitlement.productId,
            expiresOn: entitlement.expiresOn.flatMap { GraphQLHelpers.parseISO8601($0) }
        )
    }

    static func quotaState(_ quota: VinariumGraphQL.QuotaFields) -> QuotaState {
        QuotaState(
            isPremium: quota.plan.value == .premium,
            used: quota.used,
            limit: quota.limit,
            remaining: quota.remaining,
            welcomeRemaining: quota.welcomeRemaining,
            totalRemaining: quota.totalRemaining,
            renewsOn: GraphQLHelpers.parseISO8601(quota.renewsOn)
        )
    }
}
