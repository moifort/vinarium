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

    private let tileSide: CGFloat = 116
    private let tileRadius: CGFloat = 16

    /// The camera is offered only where there is one: on a simulator the
    /// picker would open on a black screen.
    private var hasCamera: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            strip
            filesRow
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task { await recentPhotos.load() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color(.secondarySystemBackground), in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fermer")
            .accessibilityIdentifier("attachment-sheet-close")

            Text("Ajouter une pièce jointe")
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            Button("Toutes les photos") { onAllPhotos() }
                .font(.subheadline)
                .lineLimit(1)
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
                Spacer(minLength: 0)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 60)
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
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
        }
}
