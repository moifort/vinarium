import SwiftUI

struct CellarInfoSettingsView: View {
    @State private var info: CellarSettingsInfo?
    @State private var error: String?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                CenteredProgressView()
            } else {
                Form {
                    if let info {
                        Section("Grille") {
                            LabeledInfoRow(
                                title: "Rangées",
                                value: "\(info.rows)",
                                icon: "rectangle.split.3x1"
                            )
                            LabeledInfoRow(
                                title: "Colonnes",
                                value: "\(info.cols)",
                                icon: "rectangle.split.1x2"
                            )
                            LabeledInfoRow(
                                title: "Capacité totale",
                                value: "\(info.capacity) bouteilles",
                                icon: "square.grid.3x3.fill"
                            )
                        }
                        Section("Occupation") {
                            LabeledInfoRow(
                                title: "Bouteilles placées",
                                value: "\(info.placedCount) / \(info.capacity)",
                                icon: "wineglass.fill"
                            )
                            if info.capacity > 0 {
                                ProgressView(
                                    value: Double(info.placedCount),
                                    total: Double(info.capacity)
                                )
                            }
                        }
                    } else if let error {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("Cave")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do {
            info = try await SettingsAPI.loadCellarInfo()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        CellarInfoSettingsView()
    }
}
