import CoreLocation
import PhotosUI
import SentrySwiftUI
import SwiftUI

enum ScanFlowResult {
    case addedToCellar
    case addedToFavorites
    case addedToRecommendations
    case added
}

struct ScanView: View {
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
                        captureCurrentLocation()
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
                ScanAnalyzingPage()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .review(let result, let imageData):
                NavigationStack {
                    ScanReviewPage(
                        scanResult: result,
                        imageData: imageData,
                        isSaving: viewModel.isSaving,
                        initialLocation: viewModel.pendingLocation,
                        onSubmit: { submission in await viewModel.submit(submission) },
                        onCancel: { viewModel.reset() }
                    )
                }

            case .placing(let id, let name, let beverageType, let color, let vintage):
                NavigationStack {
                    CellarPlacementView(
                        wineId: id,
                        wineName: name,
                        beverageType: beverageType,
                        wineColor: color,
                        wineVintage: vintage,
                        onCancel: {
                            viewModel.reset()
                        }
                    ) { position in
                        viewModel.step = .confirmed(
                            name: name,
                            beverageType: beverageType,
                            color: color,
                            position: position
                        )
                    }
                }

            case .confirmed(let name, let beverageType, let color, let position):
                NavigationStack {
                    ScanConfirmationPage(
                        wineName: name,
                        beverageType: beverageType,
                        wineColor: color,
                        position: position
                    ) {
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

            case .recommendationSaved:
                Color.clear
                    .onAppear {
                        viewModel.reset()
                        onFlowCompleted(.addedToRecommendations)
                    }

            case .saved:
                Color.clear
                    .onAppear {
                        viewModel.reset()
                        onFlowCompleted(.added)
                    }
            }
        }
        .sentryTrace("Scan Flow")
        .animation(.easeInOut(duration: 0.3), value: viewModel.step)
        .onChange(of: selectedPhoto) {
            guard let item = selectedPhoto else { return }
            selectedPhoto = nil
            viewModel.step = .scanning
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self) else {
                    viewModel.step = .camera
                    return
                }
                attachLocationFromExif(in: data)
                let jpeg = await Task.detached(priority: .userInitiated) {
                    UIImage(data: data).flatMap { $0.resized(maxDimension: 800).jpegData(compressionQuality: 0.6) }
                }.value
                if let jpeg {
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

    private func captureCurrentLocation() {
        Task {
            guard let coordinate = await LocationService.shared.requestCurrentCoordinate() else { return }
            attachLocation(coordinate)
        }
    }

    private func attachLocationFromExif(in data: Data) {
        guard let coordinate = PhotoLocationExtractor.extract(from: data) else { return }
        attachLocation(coordinate)
    }

    private func attachLocation(_ coordinate: CLLocationCoordinate2D) {
        viewModel.attachLocation(
            DiscoveryLocationDraft(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                placeName: nil
            )
        )
        Task { await viewModel.resolvePendingPlaceName() }
    }

    private func loadTestImage() {
        Task {
            let jpeg = await Task.detached(priority: .userInitiated) {
                guard let url = Bundle.main.url(forResource: "etiquette", withExtension: "jpg"),
                      let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) else { return nil as Data? }
                return image.resized(maxDimension: 800).jpegData(compressionQuality: 0.6)
            }.value
            guard let jpeg else { return }
            viewModel.step = .scanning
            viewModel.capturePhoto(jpeg)
        }
    }
}
