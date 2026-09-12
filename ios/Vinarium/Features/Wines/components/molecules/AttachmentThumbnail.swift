import SwiftUI

/// One tile in the attachment gallery: the photo itself, or the name of a
/// document under a page icon.
struct AttachmentThumbnail: View {
    let kind: BeverageAttachment.Kind
    let fileName: String
    let url: URL

    private let side: CGFloat = 84

    var body: some View {
        Group {
            switch kind {
            case .image:
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder(systemImage: "photo", caption: nil)
                    default:
                        ProgressView()
                    }
                }
            case .document:
                placeholder(systemImage: "doc.text", caption: fileName)
            }
        }
        .frame(width: side, height: side)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .accessibilityLabel(fileName)
    }

    private func placeholder(systemImage: String, caption: String?) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Document") {
    AttachmentThumbnail(
        kind: .document,
        fileName: "facture-margaux-2018.pdf",
        url: URL(string: "https://example.com/f.pdf")!
    )
    .padding()
}
