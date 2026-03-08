import Sentry
import SentrySwiftUI
import SwiftUI

struct PlacementView: View {
    let wineId: String
    let wineName: String
    let wineColor: WineColor
    let wineVintage: Int?
    var onCancel: () -> Void = {}
    let onPlaced: (String) -> Void

    @State private var bottles: [CellarBottle] = []
    @State private var suggestedRow: String?
    @State private var suggestedCol: Int?
    @State private var positionToConfirm: String?
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
                                    positionToConfirm = pos.label
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
                                    }
                                }
                                .tint(.primary)
                                .disabled(isPlacing)
                                .accessibilityIdentifier(pos.label)
                            }
                        } header: {
                            Label("Rangée \(group.row)", systemImage: "cabinet")
                        }
                    }
                }
                .alert(
                    "Placer en \(positionToConfirm ?? "") ?",
                    isPresented: Binding(
                        get: { positionToConfirm != nil },
                        set: { if !$0 { positionToConfirm = nil } }
                    )
                ) {
                    Button("Confirmer") {
                        if let position = positionToConfirm {
                            placeWine(position: position)
                        }
                    }
                    Button("Annuler", role: .cancel) {}
                }
            }
        }
        .sentryTrace("Placement", waitForFullDisplay: true)
        .navigationTitle("Placement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler", systemImage: "xmark") { onCancel() }
            }
        }
        .task {
            await loadData()
            SentrySDK.reportFullyDisplayed()
        }
    }

    private var wineHeader: some View {
        HStack(spacing: 12) {
            WineColorBadge(color: wineColor)
            VStack(alignment: .leading) {
                Text(wineName)
                    .font(.headline)
                if let vintage = wineVintage {
                    Text(verbatim: "\(vintage)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private func loadData() async {
        do {
            async let bottlesData = CellarAPI.getBottles()
            async let suggestion = CellarAPI.suggest(wineId: wineId)
            let (b, s) = try await (bottlesData, suggestion)
            bottles = b
            suggestedRow = s.row
            suggestedCol = s.col
            isLoading = false
        } catch {
            self.error = reportError(error)
            isLoading = false
        }
    }

    private func placeWine(position: String) {
        let rowStr = String(position.prefix(1))
        let col = Int(position.dropFirst()) ?? 0
        isPlacing = true

        Task {
            do {
                try await CellarAPI.place(wineId: wineId, row: rowStr, col: col)
                onPlaced(position)
            } catch {
                self.error = reportError(error)
            }
            isPlacing = false
        }
    }
}

#Preview {
    NavigationStack {
        PlacementView(
            wineId: "1",
            wineName: "Château Margaux",
            wineColor: .red,
            wineVintage: 2018,
            onPlaced: { _ in }
        )
    }
}
