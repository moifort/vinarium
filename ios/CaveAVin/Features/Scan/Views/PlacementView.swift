import SwiftUI

struct PlacementView: View {
    let wine: Wine
    let onPlaced: (String) -> Void

    @State private var bottles: [CellarBottle] = []
    @State private var suggestedRow: String?
    @State private var suggestedCol: Int?
    @State private var selectedPosition: String?
    @State private var isLoading = true
    @State private var error: String?
    @State private var isPlacing = false

    private var availablePositions: [(row: String, positions: [(label: String, rowStr: String, col: Int)])] {
        let occupied = Set(bottles.map { $0.position })
        return (0..<6).compactMap { rowIdx in
            let rowLetter = String(UnicodeScalar(65 + rowIdx)!)
            let free = (1...8).compactMap { col -> (label: String, rowStr: String, col: Int)? in
                let label = "\(rowLetter)\(col)"
                guard !occupied.contains(label) else { return nil }
                return (label: label, rowStr: rowLetter, col: col)
            }
            guard !free.isEmpty else { return nil }
            return (row: rowLetter, positions: free)
        }
    }

    private var activePosition: String {
        selectedPosition ?? suggestedPosition ?? ""
    }

    private var suggestedPosition: String? {
        guard let row = suggestedRow, let col = suggestedCol else { return nil }
        return "\(row)\(col)"
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Chargement de la cave...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
            } else {
                wineHeader

                List {
                    ForEach(availablePositions, id: \.row) { group in
                        Section {
                            ForEach(group.positions, id: \.label) { pos in
                                Button {
                                    selectedPosition = pos.label
                                } label: {
                                    HStack {
                                        Text(pos.label)
                                            .font(.body.monospaced())
                                            .fontWeight(.medium)
                                        Spacer()
                                        if pos.label == suggestedPosition {
                                            Text("Suggéré")
                                                .font(.caption)
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(.blue)
                                                .clipShape(Capsule())
                                        }
                                        if pos.label == activePosition {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }
                                .tint(.primary)
                            }
                        } header: {
                            Label("Rangée \(group.row)", systemImage: "cabinet")
                        }
                    }
                }

                placeButton
            }
        }
        .navigationTitle("Placement")
        .task {
            await loadData()
        }
    }

    private var wineHeader: some View {
        HStack(spacing: 12) {
            WineColorBadge(color: wine.color)
            VStack(alignment: .leading) {
                Text(wine.name)
                    .font(.headline)
                if let vintage = wine.vintage {
                    Text("\(vintage)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private var placeButton: some View {
        Button {
            placeWine()
        } label: {
            if isPlacing {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Label("Placer en \(activePosition)", systemImage: "arrow.down.to.line")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isPlacing || activePosition.isEmpty)
        .padding()
        .accessibilityIdentifier("place-button")
    }

    private func loadData() async {
        do {
            async let bottlesData = CellarAPI.getBottles()
            async let suggestion = CellarAPI.suggest(wineId: wine.id)
            let (b, s) = try await (bottlesData, suggestion)
            bottles = b
            suggestedRow = s.row
            suggestedCol = s.col
            selectedPosition = "\(s.row)\(s.col)"
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    private func placeWine() {
        let pos = activePosition
        guard !pos.isEmpty else { return }
        let rowStr = String(pos.prefix(1))
        let col = Int(pos.dropFirst()) ?? 0
        isPlacing = true

        Task {
            do {
                try await CellarAPI.place(wineId: wine.id, row: rowStr, col: col)
                onPlaced(pos)
            } catch {
                self.error = error.localizedDescription
            }
            isPlacing = false
        }
    }
}
