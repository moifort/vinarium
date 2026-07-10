import SwiftUI

/// Coordinator for household sharing: loads the current household, then either
/// offers to create/join one, or manages members and invitation codes.
struct SharingSettingsView: View {
    @Environment(AuthSession.self) private var authSession

    @State private var household: Household?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var displayName = ""
    @State private var showLeaveConfirmation = false
    @State private var actionError = ErrorPresenter()

    var body: some View {
        Form {
            if isLoading {
                ProgressView("Chargement…")
            } else if let household {
                inHousehold(household)
            } else {
                noHousehold
            }
            if let loadError {
                Text(loadError).foregroundStyle(.red)
            }
        }
        .navigationTitle("Partage")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
        .overlay {
            if actionError.isRunning {
                ZStack {
                    Color.black.opacity(0.1).ignoresSafeArea()
                    ProgressView()
                }
            }
        }
        .disabled(actionError.isRunning)
        .errorAlert(actionError)
    }

    // MARK: - No household

    @ViewBuilder
    private var noHousehold: some View {
        Section {
            Text("Partagez votre cave avec les personnes de votre foyer. Chacun garde sa bibliothèque, ses notes et son journal ; seules les bouteilles en cave sont communes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        Section("Inviter quelqu'un") {
            TextField("Votre nom", text: $displayName)
            Button {
                Task { await generateInvite() }
            } label: {
                Text("Générer un code d'invitation")
            }
            .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        Section("Rejoindre un foyer") {
            JoinHouseholdForm(initialDisplayName: displayName, isWorking: actionError.isRunning) { code, name in
                Task { await join(code: code, displayName: name) }
            }
        }
    }

    // MARK: - In a household

    @ViewBuilder
    private func inHousehold(_ household: Household) -> some View {
        Section("Membres du foyer") {
            HouseholdMemberList(
                items: household.members.map {
                    .init(userId: $0.userId, name: $0.displayName, isOwner: $0.isOwner, isMe: $0.isMe)
                },
                canRemove: household.iAmOwner,
                onRemove: { userId in Task { await removeMember(userId: userId) } }
            )
        }

        Section("Invitations") {
            if household.invitations.isEmpty {
                Text("Aucun code actif").foregroundStyle(.secondary)
            }
            ForEach(household.invitations) { invite in
                InviteCodeCard(code: invite.code, expiresAt: invite.expiresAt) {
                    Task { await revoke(code: invite.code) }
                }
            }
            Button {
                Task { await generateInvite() }
            } label: {
                Label("Générer un nouveau code", systemImage: "plus")
            }
        }

        Section {
            Button("Quitter le foyer", role: .destructive) {
                showLeaveConfirmation = true
            }
            .confirmationDialog(
                "Quitter le foyer ?",
                isPresented: $showLeaveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Quitter", role: .destructive) { Task { await leave() } }
            } message: {
                Text("Vos bouteilles redeviendront visibles dans votre cave personnelle.")
            }
        }
    }

    // MARK: - Actions

    private func load() async {
        if displayName.isEmpty {
            displayName = authSession.user?.displayName ?? ""
        }
        do {
            household = try await HouseholdAPI.myHousehold()
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func generateInvite() async {
        let name = currentName
        await actionError.run {
            _ = try await HouseholdAPI.createInvitation(displayName: name)
            household = try await HouseholdAPI.myHousehold()
        }
    }

    private func join(code: String, displayName name: String) async {
        await actionError.run {
            household = try await HouseholdAPI.join(code: code, displayName: name)
        }
    }

    private func leave() async {
        await actionError.run {
            try await HouseholdAPI.leave()
            household = nil
        }
    }

    private func removeMember(userId: String) async {
        await actionError.run {
            household = try await HouseholdAPI.removeMember(userId: userId)
        }
    }

    private func revoke(code: String) async {
        await actionError.run {
            try await HouseholdAPI.revokeInvitation(code: code)
            household = try await HouseholdAPI.myHousehold()
        }
    }

    /// The name to attach to a new invitation: the viewer's own household name once
    /// they are a member, otherwise the name they typed before creating the household.
    private var currentName: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        if let me = household?.members.first(where: { $0.isMe }) { return me.displayName }
        return trimmed.isEmpty ? "Moi" : trimmed
    }
}

#Preview {
    NavigationStack {
        SharingSettingsView()
    }
    .environment(AuthSession())
}
