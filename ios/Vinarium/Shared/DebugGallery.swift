#if DEBUG
import SwiftUI

/// A DEBUG-only list of screens that are hard to reach in a live session,
/// shown instead of the app when it is launched with `-debugGallery`. It lets
/// a screen be displayed on a simulator with no signed-in account, e.g. from
/// `xcrun simctl launch booted com.polyforms.vinarium.app -debugGallery`.
/// `-debugScreen <name>` opens one entry directly, so a capture needs no tap.
struct DebugGallery: View {
    @State private var paywallTrigger: PremiumTrigger?
    @State private var feedbackShown = false

    /// The value following `-debugScreen` on the launch arguments, if any.
    private static var directScreen: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-debugScreen"), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }

    var body: some View {
        switch Self.directScreen {
        case "adminHome":
            NavigationStack { AdminDashboard() }
        case "adminSheet":
            NavigationStack { AdminDashboard(adminShown: true) }
        case "wineList":
            NavigationStack { wineList }
        default:
            gallery
        }
    }

    private var gallery: some View {
        NavigationStack {
            List {
                Section("Abonnement") {
                    Button("Paywall, découverte") { paywallTrigger = .discover }
                    Button("Paywall, scans épuisés") { paywallTrigger = .scanAllowanceSpent }
                }
                Section("Listes") {
                    NavigationLink("Liste des vins, domaines en surtitre") {
                        wineList
                    }
                }
                Section("Chargement") {
                    NavigationLink("Rideau d'ouverture") {
                        LaunchCurtain(revealing: false)
                            .toolbarVisibility(.hidden, for: .navigationBar)
                    }
                    NavigationLink("Logo (login, onboarding)") {
                        BrandLogo()
                    }
                    NavigationLink("Spinner système (tout le reste)") {
                        LoadingStateView()
                    }
                    NavigationLink("Liste en cache, échec de la mise à jour") {
                        cachedList
                    }
                    NavigationLink("Liste, page suivante") {
                        paginatedList
                    }
                    NavigationLink("Accueil en cache, échec de la mise à jour") {
                        cachedDashboard
                    }
                    NavigationLink("Cave en cache, échec de la mise à jour") {
                        cachedCellar
                    }
                }
                Section("Admin") {
                    NavigationLink("Accueil, compte admin") {
                        AdminDashboard()
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
    /// The producer above the name, and left out where the name already says it
    /// (Château Margaux, Domaine Tempier).
    private var wineList: some View {
        WineListContent(
            mode: .all,
            groups: [
                .init(label: "Octobre 2026", items: [
                    .init(id: "1", color: .white, domain: "Domaine Leflaive", name: "Les Pucelles", subtitle: "2019 • Bourgogne • 120 €", rating: 4, isFavorite: true, isInCellar: true),
                    .init(id: "2", color: .red, name: "Château Margaux", subtitle: "2018 • Bordeaux • 450 €", rating: 5, isFavorite: false, isInCellar: true),
                    .init(id: "3", color: .white, domain: "Didier Dagueneau", name: "Pouilly-Fumé Silex", subtitle: "2021 • Loire", rating: nil, isFavorite: false),
                ]),
                .init(label: "Septembre 2026", items: [
                    .init(id: "4", color: .rosé, name: "Domaine Tempier", subtitle: "2022 • Bandol", rating: 3, isFavorite: false, isInCellar: true, ownerName: "Marie"),
                    .init(id: "5", color: .red, domain: "Domaine Jean-Louis Chave", name: "Hermitage", subtitle: "2017 • Rhône • Offert par Paul D.", rating: 5, isFavorite: true),
                    .init(id: "6", beverageType: .beer, color: nil, domain: "Brasserie d'Achouffe", name: "La Chouffe", subtitle: "Belgique", rating: nil, isFavorite: false),
                ]),
            ],
            onWineTapped: { _ in }
        )
        .navigationTitle("Mes Vins")
    }

    /// A relaunch whose refresh failed: last session's wines, the retry leading them.
    private var cachedList: some View {
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
            refreshFailed: true,
            onWineTapped: { _ in }
        )
        .navigationTitle("Mes Vins")
    }

    /// The bottom of a list with another page on its way: the sentinel row spins
    /// below the last wine, on the list's background rather than on a card.
    private var paginatedList: some View {
        WineListContent(
            mode: .all,
            groups: [
                .init(label: "Septembre 2026", items: [
                    .init(id: "1", color: .red, name: "Château La Sauvageonne", subtitle: "2018 • Languedoc", rating: 4, isFavorite: true, isInCellar: true),
                    .init(id: "2", color: .white, name: "Pouilly-Fumé", subtitle: "2021 • Loire", rating: 5, isFavorite: false),
                ]),
            ],
            hasMore: true,
            onWineTapped: { _ in }
        )
        .navigationTitle("Mes Vins")
    }

    /// The home tab reopened on last session's figures, its refresh failed.
    private var cachedDashboard: some View {
        DashboardPage(
            content: .init(
                stats: .init(bottleCount: 42, capacity: 48, totalValue: 1850),
                readyToDrink: [
                    .init(id: "1", color: .red, name: "Château Margaux 2018", urgent: true, drinkUntil: 2026, position: "A3"),
                ],
                favorites: [
                    .init(id: "3", color: .red, name: "Romanée-Conti 2015", vintage: 2015, tastingDate: Date(), estimatedPrice: 3500, rating: 5),
                ],
                events: [
                    .init(isEntry: true, wineName: "Pétrus 2012", position: "C2", wineId: "5", date: Date()),
                ]
            ),
            refreshFailed: true,
            onStatsTapped: {},
            onWineTapped: { _ in },
            onSettingsTapped: {}
        )
    }

    /// The cellar tab reopened on last session's bottles, its refresh failed.
    private var cachedCellar: some View {
        CellarPage(
            displayMode: .constant(.cave),
            groups: [
                .init(label: "A", items: [
                    .init(id: "1", color: .red, title: "Château Margaux", subtitle: "2018", position: "A1"),
                    .init(id: "2", color: .white, title: "Pouilly-Fumé", subtitle: "2021", position: "A2"),
                ]),
                .init(label: "B", items: [
                    .init(id: "3", color: .rosé, title: "Domaine Tempier", subtitle: "2022", position: "B1"),
                ]),
            ],
            events: [],
            refreshFailed: true,
            onBottleTapped: { _ in },
            onRemoveRequested: { _ in },
            onEventTapped: { _ in },
            onRefresh: {}
        )
    }
}

/// The home tab as an admin sees it: the metrics button beside Settings, opening the
/// Admin screen in a sheet on sample figures.
private struct AdminDashboard: View {
    @State var adminShown = false

    var body: some View {
        DashboardPage(
            content: .init(
                stats: .init(bottleCount: 42, capacity: 48, totalValue: 1850),
                readyToDrink: [
                    .init(id: "1", color: .red, name: "Château Margaux 2018", urgent: true, drinkUntil: 2026, position: "A3"),
                ],
                favorites: [],
                events: []
            ),
            onStatsTapped: {},
            onWineTapped: { _ in },
            onSettingsTapped: {},
            onAdminTapped: { adminShown = true }
        )
        .sheet(isPresented: $adminShown) {
            NavigationStack {
                AdminPage(
                    metrics: AdminMetrics(
                        aiCostEur: 0.42,
                        infraEur: 0.19,
                        totalCostEur: 0.61,
                        totalUsers: 42,
                        premiumTotal: 5,
                        premiumMonthly: 2,
                        premiumYearly: 3,
                        revenueProceedsEur: 12.4,
                        revenueGrossEur: 17.9,
                        scans: 37,
                        cacheHits: 4,
                        vision: .init(promptTokens: 96_200, outputTokens: 9_250, thinkingTokens: 55_500),
                        enrichment: .init(promptTokens: 185_000, outputTokens: 7_400, thinkingTokens: 51_800),
                        refreshedAt: Date()
                    ),
                    onRetry: {}
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        ToolbarIconButton(title: "Fermer", systemImage: "xmark", role: .cancel) {
                            adminShown = false
                        }
                    }
                }
            }
        }
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
