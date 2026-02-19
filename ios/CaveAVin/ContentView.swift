import PhotosUI
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

enum ScanFlowResult {
    case addedToCellar
    case addedToFavorites
}

struct ContentView: View {
    @State private var selectedTab: TabSelection = .home
    @State private var showScanner = false
    @State private var cellarRefreshTrigger = UUID()
    @State private var showFavorites = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(TabSelection.home.label, systemImage: TabSelection.home.icon, value: .home) {
                DashboardView(selectedTab: $selectedTab)
            }
            .accessibilityIdentifier("tab-home")
            Tab(TabSelection.cellar.label, systemImage: TabSelection.cellar.icon, value: .cellar) {
                CellarGridView(refreshTrigger: cellarRefreshTrigger)
            }
            .accessibilityIdentifier("tab-cellar")
            Tab(TabSelection.wines.label, systemImage: TabSelection.wines.icon, value: .wines) {
                WineListView(showFavorites: $showFavorites)
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
                }
            }
        }
    }
}

struct ScanFlowView: View {
    var onFlowCompleted: (ScanFlowResult) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ScanViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var shouldCapture = false

    private var isUITest: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITestPhoto")
    }

    var body: some View {
        Group {
            switch viewModel.step {
            case .camera:
                ZStack {
                    CameraView(onCapture: { data in
                        viewModel.capturePhoto(data)
                    }, shouldCapture: $shouldCapture)
                        .ignoresSafeArea()

                    ViewfinderOverlay()

                    VStack {
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial, in: .circle)
                            }
                            .accessibilityIdentifier("scan-close-button")
                            Spacer()
                        }
                        .padding()
                        Spacer()
                    }

                    VStack {
                        Spacer()
                        HStack {
                            if isUITest {
                                Button {
                                    loadTestImage()
                                } label: {
                                    Image(systemName: "photo")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .frame(width: 56, height: 56)
                                        .background(.ultraThinMaterial, in: .circle)
                                }
                                .accessibilityIdentifier("scan-photo-picker")
                            } else {
                                PhotosPicker(
                                    selection: $selectedPhoto,
                                    matching: .images
                                ) {
                                    Image(systemName: "photo")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .frame(width: 56, height: 56)
                                        .background(.ultraThinMaterial, in: .circle)
                                }
                                .accessibilityIdentifier("scan-photo-picker")
                            }
                            Spacer()
                            Button {
                                shouldCapture = true
                            } label: {
                                Circle()
                                    .stroke(.white, lineWidth: 4)
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 60, height: 60)
                                    )
                            }
                            .accessibilityIdentifier("scan-capture-button")
                            Spacer()
                            Color.clear.frame(width: 56, height: 56)
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)
                    }
                }

            case .scanning:
                AnalyzingView()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .review(let result, let imageData):
                NavigationStack {
                    ScanReviewView(scanResult: result, imageData: imageData, isSaving: viewModel.isSaving, onSave: { request in
                        viewModel.saveWine(request)
                    }, onFavorite: { request in
                        viewModel.saveAsFavorite(request)
                    }, onCancel: {
                        viewModel.reset()
                    })
                }

            case .placing(let wine):
                NavigationStack {
                    PlacementView(wine: wine) { position in
                        viewModel.step = .confirmed(wine, position)
                    }
                }

            case .confirmed(let wine, let position):
                NavigationStack {
                    ConfirmationView(wine: wine, position: position) {
                        viewModel.reset()
                        onFlowCompleted(.addedToCellar)
                    }
                }

            case .favoriteSaved:
                Color.clear
                    .onAppear {
                        viewModel.reset()
                        onFlowCompleted(.addedToFavorites)
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.step)
        .onChange(of: selectedPhoto) {
            guard let item = selectedPhoto else { return }
            selectedPhoto = nil
            viewModel.step = .scanning
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let jpeg = image.resized(maxDimension: 800).jpegData(compressionQuality: 0.6) {
                    viewModel.capturePhoto(jpeg)
                } else {
                    viewModel.step = .camera
                }
            }
        }
        .alert("Erreur", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    private func loadTestImage() {
        guard let url = Bundle.main.url(forResource: "etiquette", withExtension: "jpg"),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data),
              let jpeg = image.resized(maxDimension: 800).jpegData(compressionQuality: 0.6) else { return }
        viewModel.step = .scanning
        viewModel.capturePhoto(jpeg)
    }
}

#Preview {
    ContentView()
}
