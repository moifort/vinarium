import SwiftUI

struct RemovalChoiceSheet: View {
    let onConsume: () -> Void
    let onGift: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        onConsume()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Consommer")
                                    .font(.body)
                                Text("Enregistrer une d\u{00E9}gustation")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "wineglass")
                                .foregroundStyle(.orange)
                                .font(.title2)
                        }
                        .padding(.vertical, 4)
                    }
                    .accessibilityIdentifier("choice-consume")

                    Button {
                        onGift()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Offrir")
                                    .font(.body)
                                Text("Offrir cette bouteille \u{00E0} quelqu'un")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "gift")
                                .foregroundStyle(.purple)
                                .font(.title2)
                        }
                        .padding(.vertical, 4)
                    }
                    .accessibilityIdentifier("choice-gift")
                }
            }
            .navigationTitle("Sortir de la cave")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RemovalChoiceSheet(onConsume: {}, onGift: {})
}
