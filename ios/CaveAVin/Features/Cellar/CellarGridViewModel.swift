import Foundation

enum CellarDisplayMode: String, CaseIterable {
    case cave = "Cave"
    case journal = "Journal"
}

@MainActor @Observable
final class CellarGridViewModel {
    var bottles: [CellarBottle] = []
    var history: [HistoryEvent] = []
    var displayMode: CellarDisplayMode = .cave
    var isLoading = false
    var error: String?

    var groupedRows: [CellarRowGroup] {
        Dictionary(grouping: bottles, by: \.rowLabel)
            .sorted(by: { $0.key < $1.key })
            .map { row, items in
                CellarRowGroup(
                    row: row,
                    items: items.sorted(by: { $0.colLabel < $1.colLabel }).map {
                        CellarRowItem(position: $0.position, wine: $0.wine, rowIndex: 0, colIndex: 0)
                    }
                )
            }
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            async let bottlesData = CellarAPI.getBottles()
            async let historyData = CellarAPI.getHistory()
            let (b, h) = try await (bottlesData, historyData)
            bottles = b
            history = h
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
