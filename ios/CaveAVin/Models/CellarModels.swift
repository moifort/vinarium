import Foundation

struct CellarConfig: Codable, Sendable {
    let rows: Int
    let cols: Int
    let name: String
}

struct GridCell: Codable, Identifiable, Sendable {
    let position: String
    let wine: Wine?
    var id: String { position }
}

struct CellarEntry: Codable, Identifiable, Sendable {
    let wineId: String
    let row: String
    let col: Int
    let dateIn: Date
    let dateOut: Date?
    let consumedDate: Date?
    let rating: Int?
    let tastingNotes: String?

    var id: String { wineId }
}

struct CellarSuggestion: Codable, Sendable {
    let row: String
    let col: Int
}

struct CellarRowGroup: Identifiable, Sendable {
    let row: String
    let items: [CellarRowItem]
    var id: String { row }
}

struct CellarRowItem: Identifiable, Sendable {
    let position: String
    let wine: Wine
    let rowIndex: Int
    let colIndex: Int
    var id: String { wine.id }
}
