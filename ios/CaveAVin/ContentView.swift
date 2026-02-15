import PhotosUI
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Scan", systemImage: "camera") {
                ScanFlowView()
            }

            Tab("Cave", systemImage: "square.grid.3x3") {
                CellarGridView()
            }

            Tab("Vins", systemImage: "list.bullet") {
                WineListView()
            }

            Tab("Stats", systemImage: "chart.bar") {
                StatsView()
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
                    CameraView { data in
                        viewModel.capturePhoto(data)
                    }

                case .scanning:
                    ProgressView("Analyse de l'étiquette...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

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
            .navigationTitle("Scanner")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if case .camera = viewModel.step {
                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images
                        ) {
                            Image(systemName: "photo.on.rectangle.angled")
                        }
                    }
                }
            }
            .onChange(of: selectedPhoto) {
                guard let item = selectedPhoto else { return }
                selectedPhoto = nil
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data),
                       let jpeg = image.jpegData(compressionQuality: 0.8) {
                        viewModel.capturePhoto(jpeg)
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
