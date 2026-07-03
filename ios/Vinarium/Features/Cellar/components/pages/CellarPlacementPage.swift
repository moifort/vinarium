import SwiftUI

struct CellarPlacementPage: View {
    let wineName: String
    var beverageType: BeverageType = .wine
    let wineColor: WineColor?
    let wineVintage: Int?
    let groups: [Group]
    let suggestedPosition: String?
    let isPlacing: Bool
    var onCancel: () -> Void = {}
    var onPlaceConfirmed: (_ position: String) -> Void

    @State private var positionToConfirm: String?

    var body: some View {
        VStack(spacing: 0) {
            wineHeader

            List {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.positions) { pos in
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
                        onPlaceConfirmed(position)
                    }
                }
                Button("Annuler", role: .cancel) {}
            }
        }
        .navigationTitle("Placement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler", systemImage: "xmark") { onCancel() }
            }
        }
    }

    private var wineHeader: some View {
        HStack(spacing: 12) {
            BeverageBadge(beverageType: beverageType, color: wineColor)
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
}

extension CellarPlacementPage {
    struct Group: Identifiable {
        let row: String
        let positions: [Position]
        var id: String { row }
    }

    struct Position: Identifiable {
        let label: String
        var id: String { label }
    }
}

#Preview {
    NavigationStack {
        CellarPlacementPage(
            wineName: "Château Margaux",
            wineColor: .red,
            wineVintage: 2018,
            groups: [
                .init(row: "A", positions: [.init(label: "A2"), .init(label: "A3"), .init(label: "A4")]),
                .init(row: "B", positions: [.init(label: "B1"), .init(label: "B5")]),
            ],
            suggestedPosition: "A3",
            isPlacing: false,
            onPlaceConfirmed: { _ in }
        )
    }
}
