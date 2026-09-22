import CoreLocation
import SwiftUI

enum ScanFlowResult {
    case addedToCellar
    case addedToFavorites
    case addedToRecommendations
    case added
}

struct ScanView: View {
    /// What the scanner opens on: the camera, or what was already chosen on the
    /// add-a-wine sheet, which goes straight to analysis.
    enum Start {
        case camera
        /// The image bytes, and where it was shot when the library knows it.
        /// Without a coordinate, the place is read from the image's EXIF.
        case photo(Data, coordinate: CLLocationCoordinate2D?)
        /// A beverage named in words, identified without a photo.
        case text(String)
    }

    let start: Start
    let onFlowCompleted: (ScanFlowResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ScanViewModel
    @State private var shouldCapture = false

    /// `description` is what was typed on the sheet: it goes with every photo
    /// read in this scanner, taken with the camera or picked.
    init(
        start: Start = .camera,
        description: String? = nil,
        onFlowCompleted: @escaping (ScanFlowResult) -> Void = { _ in }
    ) {
        self.start = start
        self.onFlowCompleted = onFlowCompleted
        let viewModel = ScanViewModel()
        viewModel.description = description
        // A photo or a text start opens on the analysis step from the first
        // frame: the camera never comes on for a scan that does not need it.
        if case .camera = start {} else { viewModel.isAnalyzing = true }
        _viewModel = State(initialValue: viewModel)
    }

    /// Started from words: there is no photo to retake, so leaving the flow
    /// leaves the scanner too.
    private var isTextStart: Bool {
        if case .text = start { return true }
        return false
    }

    private var isUITest: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITestPhoto")
    }

    var body: some View {
        cameraScreen
            .sheet(isPresented: flowPresented, onDismiss: flowDismissed) {
                flowSheet
            }
            .sheet(isPresented: $viewModel.paywallShown, onDismiss: { if isTextStart { dismiss() } }) {
                PremiumSheet(trigger: .scanAllowanceSpent)
            }
            .task {
                switch start {
                case .camera: break
                case let .photo(data, coordinate): await scan(imageData: data, coordinate: coordinate)
                case let .text(text): viewModel.identify(text)
                }
            }
            .alert("Erreur", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") {
                    viewModel.error = nil
                    // A text start kept the scanner up only to show this.
                    if isTextStart { dismiss() }
                }
            } message: {
                Text(viewModel.error ?? "")
            }
    }

    // MARK: - Camera

    /// The permanent full-screen base: the camera preview and its controls. The rest
    /// of the flow (analysis, review, placement, confirmation) is presented as a sheet
    /// on top of it.
    private var cameraScreen: some View {
        ZStack {
            // A text start never wants the camera, even for the instant between
            // the flow closing and the scanner leaving.
            if viewModel.isCameraLive && !isTextStart {
                liveCamera
            } else {
                // The camera is closed as soon as the shot leaves for analysis: the
                // rest of the flow runs over a neutral background, not over a preview
                // that would hold the hardware for nothing.
                Color.black.ignoresSafeArea()
            }
        }
    }

    private var liveCamera: some View {
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

            // The shutter alone: photos from the library are picked on the
            // add-a-wine sheet, before the camera opens.
            VStack {
                Spacer()
                Button {
                    // UI tests have no camera: the shutter reads the bundled label.
                    if isUITest { loadTestImage() } else { shouldCapture = true }
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
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Flow sheet

    /// The sheet presented as soon as a scan starts. A single `NavigationStack` chains
    /// review → placement → confirmation with cross-fades, and the analysis step is a
    /// full-frame overlay on top while the AI works. Closing or cancelling falls back to
    /// the camera; dismissal is never accidental (swipe disabled), only the buttons
    /// drive the flow.
    private var flowSheet: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    if viewModel.scanNotRecognized {
                        ScanNoResultPage(fromDescription: isTextStart, onClose: { viewModel.dismissNotRecognized() })
                            .transition(.opacity)
                    } else {
                        stepContent
                    }
                }
                .animation(.easeInOut(duration: 0.35), value: viewModel.step)
                .animation(.easeInOut(duration: 0.35), value: viewModel.scanNotRecognized)
            }

            if viewModel.isAnalyzing {
                ScanAnalyzingPage()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.isAnalyzing)
        .interactiveDismissDisabled()
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.step {
        case .camera:
            // Under the analysis overlay when the flow starts: nothing to show.
            Color.clear

        case .review(let result, let imageData):
            ScanReviewPage(
                scanResult: result,
                imageData: imageData,
                isSaving: viewModel.isSaving,
                initialLocation: viewModel.pendingLocation,
                onSubmit: { submission in await viewModel.submit(submission) },
                onCancel: { viewModel.reset() }
            )
            .transition(.opacity)

        case .placing(let id, let name, let beverageType, let color, let vintage):
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
            .transition(.opacity)

        case .confirmed(let name, let beverageType, let color, let position):
            ScanConfirmationPage(
                wineName: name,
                beverageType: beverageType,
                wineColor: color,
                position: position
            ) {
                viewModel.reset()
                onFlowCompleted(.addedToCellar)
            }
            .transition(.opacity)

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

    /// The flow sheet stays open as long as the camera step is left behind (analysis
    /// running, or the review/placement/confirmation step). A programmatic dismiss
    /// (back to `.camera`) closes it; the setter falls cleanly back to the camera.
    private var flowPresented: Binding<Bool> {
        Binding(
            get: { viewModel.isFlowActive },
            set: { if !$0 { viewModel.reset() } }
        )
    }

    /// Sends a photo that did not come from the shutter: its place is attached,
    /// then it is downsized to what the scan needs before it leaves.
    private func scan(imageData data: Data, coordinate: CLLocationCoordinate2D?) async {
        if let coordinate {
            attachLocation(coordinate)
        } else {
            attachLocationFromExif(in: data)
        }
        let jpeg = await Task.detached(priority: .userInitiated) {
            UIImage(data: data).flatMap { $0.resized(maxDimension: 800).jpegData(compressionQuality: 0.6) }
        }.value
        if let jpeg {
            viewModel.capturePhoto(jpeg)
        } else {
            viewModel.isAnalyzing = false
        }
    }

    /// The flow sheet is gone: the deferred paywall comes up, or, for a scan
    /// started from words, the scanner closes rather than show a camera nobody
    /// asked for. Not while an error is up: the alert closes it instead.
    private func flowDismissed() {
        viewModel.flushPendingOutcome()
        if isTextStart && !viewModel.paywallShown && viewModel.error == nil { dismiss() }
    }

    // MARK: - Location

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
            TastingLocationDraft(
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
            viewModel.capturePhoto(jpeg)
        }
    }
}

#Preview {
    // The canvas has no camera: `CameraView` wires no input and the screen stays
    // on its controls over an empty preview layer.
    ScanView()
}
