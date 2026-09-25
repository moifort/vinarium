// Renders the system launch image, ios/Vinarium/Resources/LaunchField@{2,3}x.png,
// from the app's own `CapsuleField` at time zero, at the capsule size
// `LaunchCurtain` shows it, so the static launch screen and the first SwiftUI
// frame are the same picture. The image is as large as the largest iPhone and
// centred by the launch screen, which crops it; the live field is centred too,
// so the capsules land on the same pixels whatever the device.
//
// Loose files, not an asset catalog image set: the launch screen the system
// generates at install leaves a catalog image out and shows the bare colour
// (seen on iOS 26.5, whatever the image's size or compression), while a PNG in
// the bundle is drawn.
//
// Run from the repo root (several sources, so it is compiled rather than interpreted):
//
//   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swiftc -O -parse-as-library \
//     scripts/generate-launch-image.swift \
//     ios/Vinarium/Shared/Components/CapsuleDrawing.swift \
//     ios/Vinarium/Shared/Components/CapsuleField.swift \
//     -o /tmp/generate-launch-image && /tmp/generate-launch-image
//
// The field is drawn on a transparent background: the launch screen paints the
// charcoal itself, from the `LaunchBackground` colour set.

import AppKit
import SwiftUI

@main
struct GenerateLaunchImage {
    /// Mirrors `LaunchCurtain.capsuleSize`; the curtain file is not compiled here.
    static let capsuleSize: CGFloat = 44
    /// The largest iPhone, the Pro Max (440 x 956 points); the app is iPhone
    /// only.
    static let size = CGSize(width: 440, height: 956)

    @MainActor
    static func main() throws {
        let root = FileManager.default.currentDirectoryPath
        let folder = URL(fileURLWithPath: root).appendingPathComponent("ios/Vinarium/Resources")

        // No 1x device runs iOS 26.
        for scale in 2...3 {
            let renderer = ImageRenderer(
                content: CapsuleFieldView(capsuleSize: capsuleSize, time: 0)
                    .frame(width: size.width, height: size.height)
            )
            renderer.scale = CGFloat(scale)
            guard let cgImage = renderer.cgImage else { throw Failure.noImage(scale) }
            let png = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:])!
            let filename = "LaunchField@\(scale)x.png"
            try png.write(to: folder.appendingPathComponent(filename))
            print("\(filename): \(cgImage.width)x\(cgImage.height), \(png.count / 1024) KiB")
        }
    }

    enum Failure: Error {
        case noImage(Int)
    }
}
