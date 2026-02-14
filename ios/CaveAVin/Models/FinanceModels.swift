import Foundation

struct MonthlyReport: Codable, Sendable {
    let month: String
    let cellarValue: Double
    let entriesCount: Int
    let entriesValue: Double
    let exitsCount: Int
    let exitsValue: Double
}

struct ColorStat: Codable, Sendable {
    let count: Int
    let value: Double
}

struct RegionStat: Codable, Sendable {
    let count: Int
    let value: Double
}

struct PriceRange: Codable, Sendable {
    let range: String
    let count: Int
}

struct TrendData: Codable, Sendable {
    let lastMonthDelta: Double
    let last3MonthsDelta: Double
    let last12MonthsDelta: Double
}

struct FinanceSummary: Codable, Sendable {
    let currentValue: Double
    let bottleCount: Int
    let averagePrice: Double
    let byColor: [String: ColorStat]
    let byRegion: [String: RegionStat]
    let byPriceRange: [PriceRange]
    let monthlyHistory: [MonthlyReport]
    let trend: TrendData
}
