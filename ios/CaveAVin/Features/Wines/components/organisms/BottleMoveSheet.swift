import Sentry
import SentrySwiftUI
import SwiftUI

struct BottleMoveSheet: View {
    let wineId: String
    let wineName: String
    let wineColor: WineColor
    let wineVintage: Int?
    let currentRow: String
    let currentCol: Int
    var onCancel: () -> Void = {}
    let onMoved: () -> Void

    @State private var bottles: [CellarBottle] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var isMoving = false
    @State private var pending: Pending?

    struct Pending: Identifiable {
        let id = UUID()
        let row: String
        let col: Int
        let occupant: Occupant?

        var position: String { "\(row)\(col)" }

        struct Occupant {
            let name: String
            let color: WineColor
        }
    }

    private var currentPosition: String { "\(currentRow)\(currentCol)" }

    private var groups: [Group] {
        let occupantByPosition = Dictionary(uniqueKeysWithValues: bottles.map { ($0.position, $0) })
        return (0..<6).map { rowIdx in
            let rowLetter = String(UnicodeScalar(65 + rowIdx)!)
            let cells = (1...8).map { col -> Cell in
                let label = "\(rowLetter)\(col)"
                if label == currentPosition {
                    return Cell(row: rowLetter, col: col, label: label, state: .current)
                }
                if let occupant = occupantByPosition[label] {
                    return Cell(
                        row: rowLetter, col: col, label: label,
                        state: .occupied(name: occupant.wine.name, color: occupant.wine.color)
                    )
                }
                return Cell(row: rowLetter, col: col, label: label, state: .empty)
            }
            return Group(row: rowLetter, cells: cells)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView("Chargement de la cave...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error {
                    ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    wineHeader

                    List {
                        ForEach(groups) { group in
                            Section {
                                ForEach(group.cells) { cell in
                                    cellRow(cell)
                                }
                            } header: {
                                Label("Rangée \(group.row)", systemImage: "cabinet")
                            }
                        }
                    }
                    .alert(
                        pending?.occupant == nil
                            ? "Déplacer en \(pending?.position ?? "") ?"
                            : "Échanger avec \(pending?.occupant?.name ?? "") (\(pending?.position ?? "")) ?",
                        isPresented: Binding(
                            get: { pending != nil },
                            set: { if !$0 { pending = nil } }
                        )
                    ) {
                        Button("Confirmer") {
                            if let target = pending {
                                moveBottle(row: target.row, col: target.col)
                            }
                        }
                        Button("Annuler", role: .cancel) {}
                    }
                }
            }
            .sentryTrace("Bottle Move", waitForFullDisplay: true)
            .navigationTitle("Déplacer")
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
    }

    @ViewBuilder
    private func cellRow(_ cell: Cell) -> some View {
        switch cell.state {
        case .current:
            HStack {
                Text(cell.label)
                    .font(.body.monospaced())
                    .fontWeight(.medium)
                Spacer()
                Text("Ici")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.gray)
                    .clipShape(Capsule())
            }
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("move-\(cell.label)")

        case .empty:
            Button {
                pending = Pending(row: cell.row, col: cell.col, occupant: nil)
            } label: {
                HStack {
                    Text(cell.label)
                        .font(.body.monospaced())
                        .fontWeight(.medium)
                    Spacer()
                }
            }
            .tint(.primary)
            .disabled(isMoving)
            .accessibilityIdentifier("move-\(cell.label)")

        case let .occupied(name, color):
            Button {
                pending = Pending(
                    row: cell.row, col: cell.col,
                    occupant: Pending.Occupant(name: name, color: color)
                )
            } label: {
                HStack(spacing: 12) {
                    Text(cell.label)
                        .font(.body.monospaced())
                        .fontWeight(.medium)
                    WineColorBadge(color: color)
                    Text(name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.primary)
            .disabled(isMoving)
            .accessibilityIdentifier("move-\(cell.label)")
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
                Text("Actuellement en \(currentPosition)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private func loadData() async {
        do {
            bottles = try await CellarAPI.getBottles()
            isLoading = false
        } catch {
            self.error = reportError(error)
            isLoading = false
        }
    }

    private func moveBottle(row: String, col: Int) {
        isMoving = true
        Task {
            do {
                try await CellarAPI.move(wineId: wineId, row: row, col: col)
                onMoved()
            } catch {
                self.error = reportError(error)
            }
            isMoving = false
        }
    }
}

extension BottleMoveSheet {
    struct Group: Identifiable {
        let row: String
        let cells: [Cell]
        var id: String { row }
    }

    struct Cell: Identifiable {
        let row: String
        let col: Int
        let label: String
        let state: State
        var id: String { label }

        enum State {
            case empty
            case occupied(name: String, color: WineColor)
            case current
        }
    }
}

#Preview {
    BottleMoveSheet(
        wineId: "preview",
        wineName: "Château Margaux",
        wineColor: .red,
        wineVintage: 2018,
        currentRow: "A",
        currentCol: 1,
        onMoved: {}
    )
}
