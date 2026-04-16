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
    var icon: String {
        switch self {
        case .home: "house"
        case .cellar: "square.grid.3x3"
        case .wines: "list.bullet"
        case .scan: "camera"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: TabSelection = .home
    @State private var showScanner = false
    @State private var cellarRefreshTrigger = UUID()
    @State private var showFavorites = false
    @State private var showShortlist = false
    @State private var showRecommended = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(TabSelection.home.label, systemImage: TabSelection.home.icon, value: .home) {
                DashboardView(selectedTab: $selectedTab)
            }
            .accessibilityIdentifier("tab-home")
            Tab(TabSelection.cellar.label, systemImage: TabSelection.cellar.icon, value: .cellar) {
                CellarView(refreshTrigger: cellarRefreshTrigger)
            }
            .accessibilityIdentifier("tab-cellar")
            Tab(TabSelection.wines.label, systemImage: TabSelection.wines.icon, value: .wines) {
                WineListView(showFavorites: $showFavorites, showShortlist: $showShortlist, showRecommended: $showRecommended)
            }
            .accessibilityIdentifier("tab-wines")
            Tab(value: .scan, role: .search) {
                Color.clear
            } label: {
                Label(TabSelection.scan.label, systemImage: TabSelection.scan.icon)
            }
            .accessibilityIdentifier("tab-scan")
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .scan {
                selectedTab = oldValue
                showScanner = true
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            ScanFlowView { result in
                showScanner = false
                switch result {
                case .addedToCellar:
                    selectedTab = .cellar
                    cellarRefreshTrigger = UUID()
                case .addedToFavorites:
                    selectedTab = .wines
                    showFavorites = true
                case .addedToShortlist:
                    selectedTab = .wines
                    showShortlist = true
                case .addedToRecommendations:
                    selectedTab = .wines
                    showRecommended = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
