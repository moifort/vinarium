#if DEBUG
import SwiftUI

/// A DEBUG-only list of screens that are hard to reach in a live session,
/// shown instead of the app when it is launched with `-debugGallery`. It lets
/// a screen be displayed on a simulator with no signed-in account, e.g. from
/// `xcrun simctl launch booted com.polyforms.vinarium.app -debugGallery`.
struct DebugGallery: View {
    @State private var paywallTrigger: PremiumTrigger?
    @State private var feedbackShown = false

    var body: some View {
        NavigationStack {
            List {
                Section("Abonnement") {
                    Button("Paywall, découverte") { paywallTrigger = .discover }
                    Button("Paywall, scans épuisés") { paywallTrigger = .scanAllowanceSpent }
                }
                Section("Chargement") {
                    NavigationLink("Verre de vin (premier chargement)") {
                        LoadingStateView()
                    }
                    NavigationLink("Liste en cache, mise à jour") {
                        cachedList(refreshFailed: false)
                    }
                    NavigationLink("Liste en cache, échec de la mise à jour") {
                        cachedList(refreshFailed: true)
                    }
                }
                Section("Retours") {
                    Button("Nous écrire") { feedbackShown = true }
                }
            }
            .navigationTitle("Debug")
        }
        .sheet(item: $paywallTrigger) { trigger in
            PremiumSheet(trigger: trigger)
                .environment(SubscriptionStore())
        }
        .sheet(isPresented: $feedbackShown) {
            FeedbackSheet()
        }
    }
}

extension DebugGallery {
    /// What a relaunch looks like: last session's wines readable at once, the spinner
    /// row leading them while the server answers — or the retry when it never did.
    private func cachedList(refreshFailed: Bool) -> some View {
        WineListContent(
            mode: .all,
            groups: [
                .init(label: "Septembre 2026", items: [
                    .init(id: "1", color: .red, name: "Château La Sauvageonne", subtitle: "2018 • Languedoc", rating: 4, isFavorite: true, isInCellar: true),
                    .init(id: "2", color: .white, name: "Pouilly-Fumé", subtitle: "2021 • Loire", rating: 5, isFavorite: false),
                ]),
                .init(label: "Août 2026", items: [
                    .init(id: "3", color: .rosé, name: "Domaine Tempier", subtitle: "2022 • Bandol", rating: 3, isFavorite: false, isInCellar: true, ownerName: "Marie"),
                ]),
            ],
            isRefreshing: !refreshFailed,
            refreshFailed: refreshFailed,
            onWineTapped: { _ in }
        )
        .navigationTitle("Mes Vins")
    }
}

/// `sheet(item:)` needs an identity; the case name is one.
extension PremiumTrigger: Identifiable {
    var id: String { String(describing: self) }
}

#Preview {
    DebugGallery()
}
#endif
