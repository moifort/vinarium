import CoreLocation
import SwiftUI
import UIKit

/// How a wine gets in, chosen on this sheet and acted on once it is closed:
/// the scanner and the picker are presentations of their own and would fight
/// the sheet on its way out.
enum AddWineSource {
    case camera
    case photo(Data, coordinate: CLLocationCoordinate2D?)
    case library
    case text(String)
}

/// The sheet behind the tab bar's scan button, laid out as the attachment
/// sheet: the camera and the last photos in one strip, ready to tap. A label
/// shot a minute ago is one tap away instead of a trip through the picker.
/// Under the strip, a field for what the label does not say: sent on its own,
/// the AI names the wine from it; left there, it goes with the photo chosen.
struct AddWineSheet: View {
    @Binding var description: String
    var onCamera: () -> Void = {}
    var onAllPhotos: () -> Void = {}
    var onPickedPhoto: (Data, CLLocationCoordinate2D?) -> Void = { _, _ in }
    var onText: (String) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var recentPhotos = RecentPhotos()
    @State private var loadingPhotoId: String?
    @FocusState private var descriptionFocused: Bool

    /// Scaled with the text: a tile whose label grows while its frame stays
    /// put is a tile whose label gets cut in half.
    @ScaledMetric(relativeTo: .body) private var tileSide: CGFloat = 116
    @ScaledMetric(relativeTo: .title3) private var closeSide: CGFloat = 36
    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 60
    /// Two lines of footnote, the most the hint under the field takes.
    @ScaledMetric(relativeTo: .footnote) private var hintHeight: CGFloat = 36
    private let tileRadius: CGFloat = 16
    private static let maxDescriptionLength = 300
    private let padding: CGFloat = 20

    /// The sheet asks for exactly what it lays out, so nothing is clipped at a
    /// larger text size. The last term is the home indicator's own room.
    private var sheetHeight: CGFloat {
        padding + closeSide + padding + tileSide + padding + rowHeight + 8 + hintHeight + padding + 34
    }

    /// UI tests stub the camera with a bundled label (`-UITestPhoto`).
    private var isUITest: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITestPhoto")
    }

    /// The camera is offered only where there is one: on a simulator the
    /// scanner would open on a black screen. UI tests run there with the
    /// camera stubbed, so they keep the tile.
    private var hasCamera: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera) || isUITest
    }

    var body: some View {
        VStack(alignment: .leading, spacing: padding) {
            header
            strip
            descriptionRow
        }
        .padding(padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(sheetHeight), .large])
        .presentationDragIndicator(.visible)
        .task {
            // Under UI tests the library is left alone: its permission alert
            // would stand over the sheet and block the camera tile.
            guard !isUITest else { return }
            await recentPhotos.load()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(width: closeSide, height: closeSide)
                    .background(Color(.secondarySystemBackground), in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fermer")
            .accessibilityIdentifier("add-wine-close")

            Text("Ajouter un vin")
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            Button("Toutes les photos") { onAllPhotos() }
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .layoutPriority(1)
                .accessibilityIdentifier("add-wine-library")
        }
    }

    private var strip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                if hasCamera {
                    cameraTile
                }
                switch recentPhotos.access {
                case .pending:
                    ForEach(0 ..< 3, id: \.self) { _ in placeholderTile }
                case .granted:
                    ForEach(Array(recentPhotos.photos.enumerated()), id: \.element.id) { index, photo in
                        photoTile(photo, at: index)
                    }
                case .denied:
                    permissionTile
                }
            }
        }
        .scrollClipDisabled()
    }

    private var cameraTile: some View {
        Button { onCamera() } label: {
            tileBackground {
                VStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.title2)
                    Text("Scanner l'étiquette")
                        .font(.footnote)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.center)
                }
                .padding(8)
                .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("add-wine-camera")
    }

    private func photoTile(_ photo: RecentPhotos.Photo, at index: Int) -> some View {
        Button { pick(photo) } label: {
            Image(uiImage: photo.thumbnail)
                .resizable()
                .scaledToFill()
                .frame(width: tileSide, height: tileSide)
                .clipShape(.rect(cornerRadius: tileRadius))
                .overlay {
                    if loadingPhotoId == photo.id {
                        ZStack {
                            Color.black.opacity(0.35)
                            ProgressView().tint(.white)
                        }
                        .clipShape(.rect(cornerRadius: tileRadius))
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(loadingPhotoId != nil)
        .accessibilityLabel("Photo récente")
        .accessibilityIdentifier("add-wine-recent-photo-\(index)")
    }

    /// Without library access there is nothing to lay out, so the tile says so
    /// and leads where the decision is reversed.
    private var permissionTile: some View {
        Button {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        } label: {
            tileBackground {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                    Text("Autoriser les photos")
                        .font(.footnote)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.center)
                }
                .padding(8)
                .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("add-wine-photos-permission")
    }

    private var placeholderTile: some View {
        tileBackground { Color.clear }
    }

    private func tileBackground(@ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(width: tileSide, height: tileSide)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: tileRadius))
    }

    /// What the label does not say, or the wine itself when there is no photo:
    /// the arrow sends it alone, a photo chosen afterwards carries it along.
    private var descriptionRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.title3)
                TextField("Un vin, l'IA trouve le reste", text: $description)
                    .focused($descriptionFocused)
                    .submitLabel(.search)
                    .onSubmit(submitDescription)
                    .accessibilityIdentifier("add-wine-description")
                    // The server takes up to 300 characters: past that, typing
                    // stops rather than the scan failing.
                    .onChange(of: description) { _, text in
                        if text.count > Self.maxDescriptionLength {
                            description = String(text.prefix(Self.maxDescriptionLength))
                        }
                    }
                if !trimmedDescription.isEmpty {
                    Button(action: submitDescription) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.tint)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Rechercher")
                    .accessibilityIdentifier("add-wine-description-search")
                }
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: rowHeight)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 18))
            .contentShape(.rect)
            .onTapGesture { descriptionFocused = true }

            Text("Envoyé seul avec la flèche, ou joint à la photo choisie.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
    }

    private var trimmedDescription: String {
        description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func submitDescription() {
        guard !trimmedDescription.isEmpty else { return }
        onText(trimmedDescription)
    }

    /// The full-size photo is fetched on the tap and handed over at the size
    /// the scanner sends, barely compressed: the scanner encodes it once more.
    /// Its place travels alongside, since the decoded image has lost its EXIF.
    private func pick(_ photo: RecentPhotos.Photo) {
        loadingPhotoId = photo.id
        Task {
            let image = await recentPhotos.fullImage(id: photo.id)
            let jpeg = await Task.detached(priority: .userInitiated) {
                image.flatMap { $0.resized(maxDimension: 800).jpegData(compressionQuality: 0.9) }
            }.value
            loadingPhotoId = nil
            guard let jpeg else { return }
            onPickedPhoto(jpeg, recentPhotos.coordinate(id: photo.id))
        }
    }
}

#Preview {
    Color(.systemGroupedBackground)
        .sheet(isPresented: .constant(true)) {
            AddWineSheet(description: .constant(""))
        }
}
