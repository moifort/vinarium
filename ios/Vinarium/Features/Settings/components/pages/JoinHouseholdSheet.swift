import SwiftUI

/// A pending invitation to join, carried from an `onOpenURL` universal link to the
/// sheet that presents it. Identifiable so it can drive `.sheet(item:)`.
struct HouseholdJoinRequest: Identifiable {
    let code: String
    var id: String { code }
}

/// Standalone join screen presented when the app opens an invitation universal
/// link. The code arrives pre-filled from the link; the name comes from the
/// account (`me.firstName`). On success it confirms, then dismisses.
struct JoinHouseholdSheet: View {
    let code: String
    var onJoined: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String?
    @State private var isJoining = false
    @State private var joined = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(code)
                        .font(.system(.title, design: .monospaced).weight(.bold))
                        .tracking(6)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .textSelection(.enabled)
                } header: {
                    Text("Code d'invitation")
                } footer: {
                    Text("Rejoignez ce foyer pour partager la cave commune : les vins placés en cave sont visibles par tous ses membres. Votre bibliothèque, vos notes et votre journal restent personnels.")
                }

                if joined {
                    Section {
                        Label("Vous avez rejoint le foyer", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                } else {
                    Section {
                        Button {
                            Task { await join() }
                        } label: {
                            if isJoining {
                                ProgressView()
                            } else {
                                Text("Rejoindre le foyer")
                            }
                        }
                        .disabled(isJoining)
                    } footer: {
                        if let error {
                            Text(error).foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("Rejoindre un foyer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ToolbarIconButton(
                        title: joined ? "Terminé" : "Annuler",
                        systemImage: "xmark",
                        role: .cancel
                    ) { dismiss() }
                }
            }
            .task {
                if firstName == nil {
                    firstName = try? await OnboardingAPI.loadMe().firstName
                }
            }
        }
        .interactiveDismissDisabled(isJoining)
    }

    private func join() async {
        isJoining = true
        error = nil
        do {
            let name = (firstName ?? "").trimmingCharacters(in: .whitespaces)
            _ = try await HouseholdAPI.join(code: code, displayName: name.isEmpty ? "Moi" : name)
            joined = true
            onJoined()
        } catch {
            self.error = error.localizedDescription
        }
        isJoining = false
    }
}

#Preview {
    JoinHouseholdSheet(code: "K7P2QM")
}
