import PhotosUI
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Accueil", systemImage: "house") {
                DashboardView()
            }

            Tab("Cave", systemImage: "square.grid.3x3") {
                CellarGridView()
            }

            Tab("Vins", systemImage: "list.bullet") {
                WineListView()
            }

            Tab("Scanner", systemImage: "camera", role: .search) {
                ScanFlowView()
            }
        }
    }
}

struct ScanFlowView: View {
    @State private var viewModel = ScanViewModel()
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.step {
                case .camera:
                    ZStack(alignment: .bottom) {
                        CameraView { data in
                            viewModel.capturePhoto(data)
                        }

                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images
                        ) {
                            Image(systemName: "photo")
                                .font(.title)
                                .frame(width: 56, height: 56)
                        }
                        .glassEffect(.regular, in: .circle)
                        .padding(.bottom, 42)
                        .offset(x: -90)
                    }

                case .scanning:
                    AnalyzingView()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))

                case .review(let result, let imageData):
                    ScanReviewView(scanResult: result, imageData: imageData) { request in
                        viewModel.saveWine(request)
                    }

                case .placing(let wine):
                    PlacementView(wine: wine) { position in
                        viewModel.step = .confirmed(wine, position)
                    }

                case .confirmed(let wine, let position):
                    ConfirmationView(wine: wine, position: position) {
                        viewModel.reset()
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.step)
            .navigationTitle("Scanner")
            .onChange(of: selectedPhoto) {
                guard let item = selectedPhoto else { return }
                selectedPhoto = nil
                viewModel.step = .scanning
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data),
                       let jpeg = image.jpegData(compressionQuality: 0.8) {
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
    }
}

#Preview {
    ContentView()
}
