@preconcurrency import AVFoundation
import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    let onCapture: @MainActor (Data) -> Void
    @Binding var shouldCapture: Bool

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.onCapture = onCapture
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        if shouldCapture {
            uiViewController.capturePhoto()
            DispatchQueue.main.async { shouldCapture = false }
        }
    }
}

@MainActor
final class CameraViewController: UIViewController {
    var onCapture: (@MainActor (Data) -> Void)?

    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let delegateHandler = PhotoCaptureDelegate()

    override func viewDidLoad() {
        super.viewDidLoad()
        delegateHandler.viewController = self
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCamera() {
        captureSession.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              captureSession.canAddInput(input),
              captureSession.canAddOutput(photoOutput) else { return }

        captureSession.addInput(input)
        captureSession.addOutput(photoOutput)

        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        self.previewLayer = preview

        let session = captureSession
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: delegateHandler)
    }

    func handleCapturedPhoto(_ data: Data) {
        onCapture?(data)
    }
}

final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    @MainActor weak var viewController: CameraViewController?

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }
        if let image = UIImage(data: data), let jpeg = image.resized(maxDimension: 800).jpegData(compressionQuality: 0.6) {
            Task { @MainActor in
                self.viewController?.handleCapturedPhoto(jpeg)
            }
        }
    }
}
