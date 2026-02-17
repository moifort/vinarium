import Foundation

struct DashboardData: Codable, Sendable {
    let bottleCount: Int
    let totalValue: Double
    let readyToDrink: [DashboardWine]
    let lastBottle: DashboardEntry?
    let lastExit: DashboardHistoryEvent?
    let history: [DashboardHistoryEvent]
}

struct DashboardWine: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let color: WineColor
    let domain: String?
    let vintage: Int?
    let region: String?
}

struct DashboardEntry: Codable, Sendable {
    let wine: DashboardEntryWine
    let position: String
    let date: Date
    let rating: Int?
}

struct DashboardEntryWine: Codable, Sendable {
    let id: String
    let name: String
    let color: WineColor
    let vintage: Int?
}

struct DashboardHistoryEvent: Codable, Identifiable, Sendable {
    let type: String
    let date: Date
    let wineId: String
    let wineName: String
    let wineColor: WineColor
    let position: String
    let rating: Int?

    var id: String { "\(type)-\(wineName)-\(date.timeIntervalSince1970)" }

    var isEntry: Bool { type == "in" }
}
