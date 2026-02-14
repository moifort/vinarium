import Foundation

struct CellarConfig: Codable, Sendable {
    let rows: Int
    let cols: Int
    let name: String
}

struct GridCell: Codable, Sendable {
    let position: String
    let wine: Wine?
}

struct CellarEntry: Codable, Identifiable, Sendable {
    let wineId: String
    let row: String
    let col: Int
    let dateIn: Date
    let dateOut: Date?

    var id: String { wineId }
}

struct CellarSuggestion: Codable, Sendable {
    let row: String
    let col: Int
}
