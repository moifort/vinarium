import SwiftUI

/// The files hung on a sheet, as a shelf of tiles the height of covers, scrolled
/// sideways past the width: photos, documents under their name, and a dashed tile to
/// add one while there is room. Shown for a wine as for a whisky or a beer.
/// Presentational: the pickers, the upload and the viewer belong to the screen.
struct AttachmentShelf: View {
    let attachments: [BeverageAttachment]
    /// False on a housemate's bottle: their files are readable, not editable.
    let canEdit: Bool
    let isUploading: Bool
    var onAdd: () -> Void = {}
    var onOpen: (BeverageAttachment) -> Void = { _ in }
    var onDelete: (BeverageAttachment) -> Void = { _ in }

    /// Mirrors the server ceiling, so the tile disappears at the same moment the
    /// server would start refusing.
    private static let maximum = 5
    private static let tile = CGSize(width: 104, height: 140)

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(attachments) { attachment in
                    Button { onOpen(attachment) } label: {
                        AttachmentThumbnail(
                            kind: attachment.kind,
                            fileName: attachment.fileName,
                            url: attachment.url,
                            size: Self.tile,
                            cornerRadius: 14
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if canEdit {
                            Button("Supprimer", systemImage: "trash", role: .destructive) {
                                onDelete(attachment)
                            }
                        }
                    }
                    .accessibilityIdentifier("attachment-\(attachment.id)")
                }
                if canEdit && attachments.count < Self.maximum {
                    addTile
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }

    private var addTile: some View {
        Button(action: onAdd) {
            VStack(spacing: 6) {
                if isUploading {
                    ProgressView()
                } else {
                    Image(systemName: "plus")
                        .font(.title2)
                    Text("Ajouter")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .foregroundStyle(.tint)
            .frame(width: Self.tile.width, height: Self.tile.height)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color(.tertiaryLabel), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
            )
            .contentShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(isUploading)
        .accessibilityIdentifier("add-attachment-button")
    }
}

#Preview("Shelf") {
    AttachmentShelf(
        attachments: [
            BeverageAttachment(
                id: "1", kind: .document, fileName: "facture.pdf", contentType: "application/pdf",
                size: 88_000, url: URL(string: "https://example.com/facture.pdf")!, createdAt: Date()
            ),
        ],
        canEdit: true,
        isUploading: false
    )
}

#Preview("Housemate, nothing") {
    AttachmentShelf(attachments: [], canEdit: false, isUploading: false)
}
