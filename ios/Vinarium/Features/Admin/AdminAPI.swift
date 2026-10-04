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
            month: AdminMetrics.monthStart(of: Date()),
            costs: m.costs.map(costs),
            sessions: m.sessions.map { entries in
                entries.compactMap { entry in
                    AdminMetrics.day(entry.day).map {
                        AdminMetrics.DailySessions(day: $0, sessions: entry.sessions)
                    }
                }
            },
            totalUsers: m.totalUsers,
            newUsers: m.newUsers,
            premiumTotal: m.premiumTotal,
            newPremium: m.newPremium,
            revenueProceedsEur: m.revenueProceedsEur,
            revenueGrossEur: m.revenueGrossEur,
            scans: m.scans,
            cacheHits: m.cacheHits,
            vision: tokens(m.vision.fragments.aiTokenUsageFields),
            enrichment: tokens(m.enrichment.fragments.aiTokenUsageFields),
            refreshedAt: m.refreshedAt.flatMap { GraphQLHelpers.parseISO8601($0) }
        )
    }

    private static func costs(
        _ costs: VinariumGraphQL.AdminMetricsQuery.Data.AdminMetrics.Costs
    ) -> AdminMetrics.Costs {
        AdminMetrics.Costs(
            geminiEur: costs.geminiEur,
            infraEur: costs.infraEur,
            totalEur: costs.totalEur,
            projectedEur: costs.projectedEur,
            previousMonthEur: costs.previousMonthEur,
            changeVsPreviousMonth: costs.changeVsPreviousMonth,
            billedThrough: costs.billedThrough.flatMap(AdminMetrics.day),
            days: costs.days.compactMap { entry in
                AdminMetrics.day(entry.day).map {
                    AdminMetrics.DailyCost(
                        day: $0,
                        geminiEur: entry.geminiEur,
                        infraEur: entry.infraEur
                    )
                }
            }
        )
    }

    private static func tokens(_ usage: VinariumGraphQL.AiTokenUsageFields) -> AdminMetrics.TokenUsage {
        AdminMetrics.TokenUsage(
            promptTokens: usage.promptTokens,
            outputTokens: usage.outputTokens,
            thinkingTokens: usage.thinkingTokens
        )
    }
}
