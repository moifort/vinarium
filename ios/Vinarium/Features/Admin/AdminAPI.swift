import Apollo
import Foundation

enum AdminAPI {
    static func metrics() async throws -> AdminMetrics {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.AdminMetricsQuery()
        )
        let m = data.adminMetrics
        return AdminMetrics(
            aiCostEur: m.aiCostEur,
            infraEur: m.infraEur,
            totalCostEur: m.totalCostEur,
            totalUsers: m.totalUsers,
            premiumTotal: m.premiumTotal,
            premiumMonthly: m.premiumMonthly,
            premiumYearly: m.premiumYearly,
            revenueProceedsEur: m.revenueProceedsEur,
            revenueGrossEur: m.revenueGrossEur,
            scans: m.scans,
            cacheHits: m.cacheHits,
            vision: AdminMetrics.TokenUsage(
                promptTokens: m.vision.promptTokens,
                outputTokens: m.vision.outputTokens,
                thinkingTokens: m.vision.thinkingTokens
            ),
            enrichment: AdminMetrics.TokenUsage(
                promptTokens: m.enrichment.promptTokens,
                outputTokens: m.enrichment.outputTokens,
                thinkingTokens: m.enrichment.thinkingTokens
            ),
            refreshedAt: m.refreshedAt.flatMap { GraphQLHelpers.parseISO8601($0) }
        )
    }
}
