import SwiftUI

struct ContentView: View {
    @State private var showScan = false

    var body: some View {
        TabView {
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showScan = true
                } label: {
                    Image(systemName: "camera")
                }
            }
        }
        .fullScreenCover(isPresented: $showScan) {
            ScanFlowView()
        }
    }
}

struct ScanFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ScanViewModel()

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
                        dismiss()
                    }
                }
            }
            .navigationTitle("Scanner")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
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
