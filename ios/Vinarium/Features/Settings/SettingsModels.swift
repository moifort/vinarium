import Foundation

struct ChangelogVersion: Identifiable, Hashable, Sendable {
    let version: String
    let date: Date?
    let notes: [String]
    var id: String { version }
}

struct CellarSettingsInfo: Sendable, Hashable {
    let rows: Int
    let cols: Int
    let capacity: Int
    let placedCount: Int
}

struct ImportSummary: Sendable, Hashable {
    let wines: Int
    let cellar: Int
    let tasting: Int
    let recommendation: Int
    let gift: Int
    let journal: Int

    var totalRecords: Int {
        wines + cellar + tasting + recommendation + gift + journal
    }
}
