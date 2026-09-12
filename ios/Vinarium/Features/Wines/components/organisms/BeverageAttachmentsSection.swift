import SwiftUI

/// The gallery on the beverage sheet, shown for a wine as for a whisky or a beer.
/// Presentational: it shows what it is given and
/// reports taps. The pickers, the upload and the viewer belong to the coordinator.
struct BeverageAttachmentsSection: View {
    let attachments: [BeverageAttachment]
    /// False on a housemate's bottle: their files are readable, not editable.
    let canEdit: Bool
    let isUploading: Bool
    var onAdd: () -> Void = {}
    var onOpen: (BeverageAttachment) -> Void = { _ in }
    var onDelete: (BeverageAttachment) -> Void = { _ in }

    /// Mirrors the server ceiling, so the button disappears at the same moment
    /// the server would start refusing.
    private static let maximum = 5

    var body: some View {
        Section("Pièces jointes") {
            if attachments.isEmpty && !canEdit {
                Text("Aucune pièce jointe")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(attachments) { attachment in
                            Button { onOpen(attachment) } label: {
                                AttachmentThumbnail(
                                    kind: attachment.kind,
                                    fileName: attachment.fileName,
                                    url: attachment.url
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
                            addButton
                        }
                    }
                    .padding(.vertical, 4)
                }
                .scrollClipDisabled()

                if canEdit && attachments.count >= Self.maximum {
                    Text("Cinq pièces jointes au maximum, la limite est atteinte.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var addButton: some View {
        Button(action: onAdd) {
            VStack(spacing: 4) {
                if isUploading {
                    ProgressView()
                } else {
                    Image(systemName: "plus")
                        .font(.title2)
                    Text("Ajouter")
                        .font(.caption2)
                }
            }
            .frame(width: 84, height: 84)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(Color(.separator))
            )
        }
        .buttonStyle(.plain)
        .disabled(isUploading)
        .accessibilityIdentifier("add-attachment-button")
    }
}

#Preview("With files") {
    List {
        BeverageAttachmentsSection(
            attachments: [
                BeverageAttachment(
                    id: "1",
                    kind: .image,
                    fileName: "etiquette.jpg",
                    contentType: "image/jpeg",
                    size: 240_000,
                    url: URL(string: "https://example.com/1.jpg")!,
                    createdAt: Date()
                ),
                BeverageAttachment(
                    id: "2",
                    kind: .document,
                    fileName: "facture-margaux-2018.pdf",
                    contentType: "application/pdf",
                    size: 88_000,
                    url: URL(string: "https://example.com/2.pdf")!,
                    createdAt: Date()
                ),
            ],
            canEdit: true,
            isUploading: false
        )
    }
}

#Preview("Empty, read only") {
    List {
        BeverageAttachmentsSection(attachments: [], canEdit: false, isUploading: false)
    }
}
