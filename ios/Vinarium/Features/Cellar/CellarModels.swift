import Foundation

/// One cellar of the household: a named grid. Every household has a primary one,
/// sized at onboarding; Premium adds more.
struct CellarSummary: Codable, Hashable, Identifiable, Sendable {
    let id: String
    /// Nil for a primary cellar nobody named: the app names it.
    let name: String?
    let isPrimary: Bool
    var rows: Int = 0
    var cols: Int = 0
    var zones: Int = 1
    var capacity: Int = 0
    var placedCount: Int = 0

    var displayName: String {
        name ?? String(localized: "Cave principale")
    }
}

extension CellarSummary {
    init(fields c: VinariumGraphQL.CellarFields) {
        self.init(
            id: c.id,
            name: c.name,
            isPrimary: c.isPrimary,
            rows: c.rows,
            cols: c.cols,
            zones: c.zones,
            capacity: c.capacity,
            placedCount: c.placedCount
        )
    }
}

/// The cellar the cave tab was left on, kept like the wine list's filters and
/// forgotten with them when the session ends. Nil means the primary cellar.
enum CellarSelection {
    private static let key = "cellar-selected"

    static func stored() -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    static func save(_ cellarId: String?) {
        if let cellarId {
            UserDefaults.standard.set(cellarId, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

/// A slot as the household reads it: "B4" while it has one cellar, "Garage · B4"
/// once it has several, so a position never leaves its cellar in doubt.
enum CellarPositionLabel {
    static func text(
        _ position: String,
        cellarId: String?,
        cellars: [(id: String, name: String?)]
    ) -> String {
        guard cellars.count > 1, let cellarId,
              let cellar = cellars.first(where: { $0.id == cellarId })
        else { return position }
        let name = cellar.name ?? String(localized: "Cave principale")
        return "\(name) · \(position)"
    }
}

struct CellarBottle: Codable, Identifiable, Sendable {
    let wineId: String
    /// The cellar the bottle stands in.
    var cellarId: String? = nil
    let wine: Wine
    let rowLabel: String
    let colLabel: Int
    let createdAt: Date
    /// The household member who owns this bottle, or nil when it is the viewer's own.
    var ownerName: String?

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
    let wineBeverageType: BeverageType
    let wineColor: WineColor?
    let position: String
    /// The household member behind the move, nil when it was you.
    let memberName: String?

    var id: String { "\(wineId)-\(type.rawValue)-\(date.timeIntervalSince1970)" }
}

/// What the cellar tab showed last time — the first page of bottles and of the
/// journal — kept on disk so a relaunch opens on it.
struct CellarSnapshot: Codable, Sendable {
    let bottles: [CellarBottle]
    let history: [HistoryEvent]
    var cellars: [CellarSummary] = []
    /// The cellar the bottles belong to.
    var cellarId: String? = nil
}

struct CellarRowGroup: Identifiable, Sendable {
    let row: String
    let items: [CellarRowItem]
    var id: String { row }
}

struct CellarRowItem: Identifiable, Sendable {
    let id: String
    let name: String
    let beverageType: BeverageType
    let color: WineColor?
    let vintage: Int?
    let position: String
    let ownerName: String?
}
