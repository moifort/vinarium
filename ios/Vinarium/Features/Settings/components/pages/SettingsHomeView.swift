import SwiftUI

struct SettingsHomeView: View {
    @Environment(AuthSession.self) private var authSession
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackShown = false
    /// Nil until loaded: the row then shows no subtitle rather than a wrong count.
    @State private var cellarCount: Int?
    /// How many other people share the cellar; 0 outside a household.
    @State private var sharedWithCount: Int?

    init(cellarCount: Int? = nil, sharedWithCount: Int? = nil) {
        _cellarCount = State(initialValue: cellarCount)
        _sharedWithCount = State(initialValue: sharedWithCount)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ProfileSettingsView()
                    } label: {
                        SettingsRow(
                            icon: "person.crop.circle.fill",
                            title: "Profil",
                            subtitle: profileSubtitle,
                            tint: .blue
                        )
                    }
                    NavigationLink {
                        PremiumView(trigger: .discover)
                    } label: {
                        SettingsRow(
                            icon: "sparkles",
                            title: subscriptions.isPremium == true ? "Vinarium Premium" : "Découvrir Premium",
                            subtitle: subscriptionSubtitle,
                            tint: .orange
                        )
                    }
                    NavigationLink {
                        CellarsSettingsView()
                    } label: {
                        SettingsRow(
                            icon: "square.grid.3x3.fill",
                            title: "Caves",
                            subtitle: cellarsSubtitle,
                            tint: .brown
                        )
                    }
                    NavigationLink {
                        SharingSettingsView()
                    } label: {
                        SettingsRow(
                            icon: "person.2.fill",
                            title: "Partage",
                            subtitle: sharingSubtitle,
                            tint: .purple
                        )
                    }
                }

                Section("Application") {
                    NavigationLink {
                        ChangelogListView()
                    } label: {
                        SettingsRow(
                            icon: "doc.text.fill",
                            title: "Version & changelog",
                            subtitle: "v\(appVersion) (\(buildNumber))",
                            tint: .indigo
                        )
                    }
                    Button {
                        feedbackShown = true
                    } label: {
                        SettingsRow(
                            icon: "envelope.fill",
                            title: "Nous écrire",
                            subtitle: "Signaler un problème ou proposer une idée",
                            tint: .pink
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            // On appear rather than once: coming back from Caves or Partage
            // must show what was just added or removed there.
            .onAppear { Task { await loadSummaries() } }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $feedbackShown) {
                FeedbackSheet()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ToolbarIconButton(title: "Fermer", systemImage: "xmark", role: .cancel) { dismiss() }
                }
            }
        }
    }

    private var profileSubtitle: String? {
        authSession.user?.displayName ?? authSession.user?.email
    }

    /// What the subscription gives today: the number of scans left on a free account,
    /// unlimited scans for a subscriber. Before the allowance is known, the offer
    /// itself, so the row never sits bare next to the others.
    private var subscriptionSubtitle: String {
        guard let quota = subscriptions.quota else {
            return subscriptions.isPremium == true
                ? String(localized: "Scans illimités")
                : String(localized: "Scans illimités et plusieurs caves")
        }
        if quota.isPremium {
            return String(localized: "Scans illimités")
        }
        // The total, granted scans included: the month alone would announce a wall
        // the user has not reached.
        return quota.totalRemaining == 0
            ? String(localized: "Aucun scan restant")
            : String(localized: "\(quota.totalRemaining) scans restants")
    }

    private var cellarsSubtitle: String? {
        cellarCount.map { String(localized: "\($0) caves") }
    }

    private var sharingSubtitle: String? {
        guard let sharedWithCount else { return nil }
        return sharedWithCount == 0
            ? String(localized: "Non partagée")
            : String(localized: "Partagée avec \(sharedWithCount) personnes")
    }

    /// Both counts load side by side; a failure keeps the previous value, the
    /// pages behind the rows report their own errors.
    private func loadSummaries() async {
        async let cellars = try? CellarAPI.cellars()
        async let sharing = try? HouseholdAPI.sharingSettings()
        if let cellars = await cellars {
            cellarCount = cellars.count
        }
        if let sharing = await sharing {
            sharedWithCount = sharing.household?.members.filter { !$0.isMe }.count ?? 0
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
}

#Preview {
    SettingsHomeView()
        .environment(AuthSession())
}
