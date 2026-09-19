import SwiftUI
import UIKit

/// Where a file comes from, picked on the sheet and acted on once it is closed.
enum AttachmentSource {
    case camera
    case library
    case files
}

/// The sheet that opens from the attachment gallery. The camera and the last
/// photos sit in one strip, ready to tap; everything else goes through the row
/// underneath, which opens the Files browser directly.
struct AttachmentSourceSheet: View {
    var onCamera: () -> Void = {}
    var onAllPhotos: () -> Void = {}
    var onFiles: () -> Void = {}
    var onPickedPhoto: (UIImage) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var recentPhotos = RecentPhotos()
    @State private var loadingPhotoId: String?

    /// Scaled with the text: a tile whose label grows while its frame stays
    /// put is a tile whose label gets cut in half.
    @ScaledMetric(relativeTo: .body) private var tileSide: CGFloat = 116
    @ScaledMetric(relativeTo: .title3) private var closeSide: CGFloat = 36
    @ScaledMetric(relativeTo: .body) private var filesRowHeight: CGFloat = 60
    private let tileRadius: CGFloat = 16
    private let padding: CGFloat = 20

    /// The sheet asks for exactly what it lays out, so nothing is clipped at a
    /// larger text size. The last term is the home indicator's own room.
    private var sheetHeight: CGFloat {
        padding + closeSide + padding + tileSide + padding + filesRowHeight + padding + 34
    }

    /// The camera is offered only where there is one: on a simulator the
    /// picker would open on a black screen.
    private var hasCamera: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: padding) {
            header
            strip
            filesRow
        }
        .padding(padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
        .task { await recentPhotos.load() }
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
            .accessibilityIdentifier("attachment-sheet-close")

            // Short on purpose: the title and "Toutes les photos" share one line,
            // and the longer wording pushed the button off the screen.
            Text("Pièce jointe")
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            Button("Toutes les photos") { onAllPhotos() }
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .layoutPriority(1)
                .accessibilityIdentifier("attachment-source-library")
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
                    Image(systemName: "camera")
                        .font(.title2)
                    Text("Appareil photo")
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
        .accessibilityIdentifier("attachment-source-camera")
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
        .accessibilityIdentifier("attachment-recent-photo-\(index)")
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
        .accessibilityIdentifier("attachment-photos-permission")
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

    private var filesRow: some View {
        Button { onFiles() } label: {
            HStack(spacing: 12) {
                Image(systemName: "doc.badge.plus")
                    .font(.title3)
                Text("Ajouter des fichiers")
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: filesRowHeight)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 18))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("attachment-source-file")
    }

    private func pick(_ photo: RecentPhotos.Photo) {
        loadingPhotoId = photo.id
        Task {
            let image = await recentPhotos.fullImage(id: photo.id)
            loadingPhotoId = nil
            guard let image else { return }
            onPickedPhoto(image)
            dismiss()
        }
    }
}

#Preview {
    Color(.systemGroupedBackground)
        .sheet(isPresented: .constant(true)) {
            AttachmentSourceSheet()
        }
}
