import Foundation

struct DashboardData: Codable, Sendable {
    let bottleCount: Int
    let readyToDrink: [DashboardWine]
    let lastEntry: DashboardEntry?
    let lastExit: DashboardEntry?
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
