import Foundation

struct CellarBottle: Codable, Identifiable, Sendable {
    let wineId: String
    let wine: Wine
    let rowLabel: String
    let colLabel: Int
    let createdAt: Date

    var id: String { wineId }
    var position: String { "\(rowLabel)\(colLabel)" }
}

struct CellarSuggestion: Codable, Sendable {
    let row: String
    let col: Int

    enum CodingKeys: String, CodingKey {
        case row = "rowLabel"
        case col = "colLabel"
    }
}

enum HistoryEventType: String, Codable, Sendable {
    case entry = "in"
    case exit = "out"
}

struct HistoryEvent: Codable, Identifiable, Sendable {
    let type: HistoryEventType
    let date: Date
    let wineId: String
    let wineName: String
    let wineColor: WineColor
    let position: String

    var id: String { "\(wineId)-\(type.rawValue)-\(date.timeIntervalSince1970)" }
}

struct CellarRowGroup: Identifiable, Sendable {
    let row: String
    let items: [CellarRowItem]
    var id: String { row }
}

struct CellarRowItem: Identifiable, Sendable {
    let id: String
    let name: String
    let color: WineColor
    let vintage: Int?
    let position: String
}
