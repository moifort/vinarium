import Foundation

enum SettingsAPI {
    static func loadChangelog() async throws -> [ChangelogVersion] {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.ChangelogQuery()
        )
        return data.changelog.map { entry in
            ChangelogVersion(
                version: entry.version,
                date: entry.date.flatMap { GraphQLHelpers.parseISO8601($0) },
                notes: entry.notes
            )
        }
    }

    static func loadCellarInfo() async throws -> CellarSettingsInfo {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.CellarInfoQuery()
        )
        let info = data.cellarInfo
        return CellarSettingsInfo(
            rows: info.rows,
            cols: info.cols,
            capacity: info.capacity,
            placedCount: info.placedCount
        )
    }

    static func exportData() async throws -> String {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: VinariumGraphQL.ExportDataQuery()
        )
        return data.exportData
    }

    static func importData(payload: String) async throws -> ImportSummary {
        let data = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.ImportDataMutation(payload: payload)
        )
        let result = data.importData
        return ImportSummary(
            wines: result.wines,
            cellar: result.cellar,
            tasting: result.tasting,
            recommendation: result.recommendation,
            gift: result.gift,
            journal: result.journal
        )
    }
}
