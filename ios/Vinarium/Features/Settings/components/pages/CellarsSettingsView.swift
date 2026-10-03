import SwiftUI

/// Settings > Caves: every cellar of the household, and the way to add one. A
/// second cellar is a Premium feature; one created while subscribed stays usable
/// afterwards.
struct CellarsSettingsView: View {
    @Environment(SubscriptionStore.self) private var subscriptions
    @State private var cellars: [CellarSummary] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showCreation = false
    @State private var premiumShown = false

    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let error {
                Text(error).foregroundStyle(.red)
            } else {
                Section {
                    ForEach(cellars) { cellar in
                        NavigationLink {
                            CellarSettingsView(cellar: cellar) {
                                Task { await load() }
                            }
                        } label: {
                            SettingsRow(
                                icon: cellar.isPrimary ? "cabinet.fill" : "square.stack.3d.up.fill",
                                title: "\(cellar.displayName)",
                                subtitle: String(localized: "\(cellar.placedCount) / \(cellar.capacity) bouteilles"),
                                tint: .brown
                            )
                        }
                        .accessibilityIdentifier("cellar-row-\(cellar.displayName)")
                    }
                }

                Section {
                    Button {
                        if subscriptions.isPremium == true {
                            showCreation = true
                        } else {
                            premiumShown = true
                        }
                    } label: {
                        Label("Ajouter une cave", systemImage: "plus")
                    }
                    .accessibilityIdentifier("add-cellar-button")
                } footer: {
                    Text("Une cave par meuble ou par pièce : chacune a sa grille. Plusieurs caves sont incluses dans Vinarium Premium.")
                }
            }
        }
        .navigationTitle("Caves")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
        .sheet(isPresented: $showCreation) {
            NewCellarView(
                onCreated: { created in cellars.append(created) },
                onPremiumRequired: {
                    showCreation = false
                    premiumShown = true
                }
            )
        }
        .sheet(isPresented: $premiumShown) {
            PremiumSheet(trigger: .moreCellars)
        }
    }

    private func load() async {
        do {
            cellars = try await CellarAPI.cellars()
            error = nil
        } catch {
            self.error = reportError(error)
        }
        isLoading = false
    }
}

/// One cellar: its name, its grid, its occupation; resize it, delete it once empty.
struct CellarSettingsView: View {
    let onChanged: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var cellar: CellarSummary
    @State private var name: String
    @State private var isReconfiguring = false
    @State private var showDeleteConfirmation = false
    @State private var actionError = ErrorPresenter()

    init(cellar: CellarSummary, onChanged: @escaping () -> Void) {
        self.onChanged = onChanged
        _cellar = State(initialValue: cellar)
        _name = State(initialValue: cellar.name ?? "")
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        Form {
            Section("Nom") {
                TextField(String(localized: "Cave principale"), text: $name)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .onSubmit { Task { await rename() } }
                    .accessibilityIdentifier("cellar-name-field")
            }
            Section("Grille") {
                LabeledInfoRow(title: "Rangées", value: "\(cellar.rows)", icon: "rectangle.split.1x2")
                LabeledInfoRow(
                    title: "Emplacements par rangée",
                    value: "\(cellar.cols)",
                    icon: "rectangle.split.3x1"
                )
                LabeledInfoRow(
                    title: "Capacité totale",
                    value: "\(cellar.capacity) bouteilles",
                    icon: "square.grid.3x3.fill"
                )
            }
            Section("Occupation") {
                OccupancyRing(placed: cellar.placedCount, capacity: cellar.capacity)
            }
            Section {
                Button {
                    isReconfiguring = true
                } label: {
                    Label("Reconfigurer la cave", systemImage: "slider.horizontal.3")
                }
            } footer: {
                Text("Choisissez un modèle du commerce ou ajustez les dimensions.")
            }
            if !cellar.isPrimary {
                Section {
                    Button("Supprimer la cave", systemImage: "trash", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .accessibilityIdentifier("delete-cellar-button")
                } footer: {
                    Text("Seule une cave vide peut être supprimée.")
                }
            }
        }
        .navigationTitle(cellar.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .errorAlert(actionError)
        .onDisappear {
            if trimmedName != (cellar.name ?? ""), !trimmedName.isEmpty {
                Task { await rename() }
            }
        }
        .confirmationDialog(
            "Supprimer cette cave ?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Supprimer", role: .destructive) {
                Task {
                    await actionError.run {
                        try await CellarAPI.delete(id: cellar.id)
                    } onSuccess: {
                        onChanged()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $isReconfiguring) {
            CellarReconfigureView(
                rows: cellar.rows,
                cols: cellar.cols,
                zones: cellar.zones,
                cellarId: cellar.id,
                onReconfigured: { info in
                    cellar.rows = info.rows
                    cellar.cols = info.cols
                    cellar.zones = info.zones
                    cellar.capacity = info.capacity
                    cellar.placedCount = info.placedCount
                    onChanged()
                }
            )
        }
    }

    private func rename() async {
        let newName = trimmedName
        guard !newName.isEmpty, newName != cellar.name else { return }
        await actionError.run {
            cellar = try await CellarAPI.rename(id: cellar.id, name: newName)
        } onSuccess: {
            onChanged()
        }
    }
}

#Preview {
    NavigationStack {
        CellarsSettingsView()
            .environment(SubscriptionStore())
    }
}
