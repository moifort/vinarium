import SwiftUI

enum TabSelection: Int, CaseIterable, Identifiable {
    case home, cellar, wines, scan
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .home: "Accueil"
        case .cellar: "Cave"
        case .wines: "Vins"
        case .scan: "Scanner"
        }
    }
}

struct ContentView: View {
    /// A pending invitation from a universal link, presented once the app is ready.
    @Binding var joinRequest: HouseholdJoinRequest?

    @State private var selectedTab: TabSelection = .home
    /// The last real content tab, restored when the scan cover is dismissed.
    @State private var lastContentTab: TabSelection = .home
    @State private var showScanner = false
    @State private var cellarRefreshTrigger = UUID()
    @State private var wineListRefreshTrigger = UUID()
    @State private var showFavorites = false
    @State private var showRecommended = false
    @State private var searchPresenter = SearchPresenter()

    /// The trailing "Scanner" entry must stay detached from the content tabs.
    /// iOS 26 separates the `.search` role; iOS 27 folded `.search` back into the
    /// main tab row and introduced `.prominent` for a trailing-separated tab.
    /// Pick the role that detaches on the running OS, guarding `.prominent`
    /// behind the SDK that defines it (Swift 6.4 / Xcode 27) so the app still
    /// builds with Xcode 26.
    private var scanTabRole: TabRole {
        #if compiler(>=6.4)
        if #available(iOS 27.0, *) {
            return .prominent
        }
        #endif
        return .search
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: .home) {
                DashboardView(selectedTab: $selectedTab)
            } label: {
                tabLabel(for: .home)
            }
            .accessibilityIdentifier("tab-home")
            Tab(value: .cellar) {
                CellarView(refreshTrigger: cellarRefreshTrigger)
            } label: {
                tabLabel(for: .cellar)
            }
            .accessibilityIdentifier("tab-cellar")
            Tab(value: .wines) {
                WineListView(
                    showFavorites: $showFavorites,
                    showRecommended: $showRecommended,
                    refreshTrigger: wineListRefreshTrigger
                )
            } label: {
                tabLabel(for: .wines)
            }
            .accessibilityIdentifier("tab-wines")
            Tab(value: .scan, role: scanTabRole) {
                Color.clear
            } label: {
                tabLabel(for: .scan)
            }
            .accessibilityIdentifier("tab-scan")
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .scan {
                showScanner = true
            } else {
                lastContentTab = newValue
            }
        }
        .environment(searchPresenter)
        .fullScreenCover(isPresented: $searchPresenter.isPresented) {
            SearchView()
        }
        .fullScreenCover(isPresented: $showScanner, onDismiss: restoreContentTab) {
            ScanView { result in
                showScanner = false
                switch result {
                case .addedToCellar:
                    selectedTab = .cellar
                    cellarRefreshTrigger = UUID()
                case .addedToFavorites:
                    selectedTab = .wines
                    showFavorites = true
                case .addedToRecommendations:
                    selectedTab = .wines
                    showRecommended = true
                case .added:
                    selectedTab = .wines
                }
            }
        }
        .sheet(item: $joinRequest) { request in
            JoinHouseholdSheet(code: request.code) {
                // The guest now shares the cave: refresh both the grid and the wine
                // list so the joined household's bottles appear without a manual
                // reload (the list and search now span the shared cellar too).
                cellarRefreshTrigger = UUID()
                wineListRefreshTrigger = UUID()
            }
        }
    }

    /// Tab bar label with a pinned Dynamic Type size, so the symbols keep a
    /// fixed size whatever the user's text size setting. Accueil and Cave use
    /// native symbols; Vins and Scanner use the custom wine-themed symbols,
    /// always in their filled form.
    @ViewBuilder
    private func tabLabel(for tab: TabSelection) -> some View {
        Group {
            switch tab {
            case .home:
                Label(tab.label, systemImage: "house")
            case .cellar:
                Label(tab.label, systemImage: "square.grid.3x3")
            case .wines:
                Label(tab.label, image: "tab.wines.fill")
            case .scan:
                Label(tab.label, image: "tab.scan.fill")
            }
        }
        .dynamicTypeSize(.large)
    }

    /// After the scan cover closes, leave the empty scan tab and return to the
    /// content tab the user came from (unless a successful scan already routed
    /// the selection elsewhere).
    private func restoreContentTab() {
        if selectedTab == .scan { selectedTab = lastContentTab }
    }
}

#Preview {
    ContentView(joinRequest: .constant(nil))
}
