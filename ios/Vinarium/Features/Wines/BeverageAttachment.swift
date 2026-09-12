import Foundation

/// A file hung on a beverage sheet, whatever the bottle is: a label photo, the
/// cellar it came from, an invoice.
struct BeverageAttachment: Identifiable, Codable, Sendable, Equatable {
    /// How to present the file. A photo is shown inline in the gallery, anything
    /// else is opened in the document viewer.
    enum Kind: String, Codable, Sendable {
        case image
        case document
    }

    let id: String
    let kind: Kind
    let fileName: String
    let contentType: String
    let size: Int
    /// Signed for one hour, for this file only. Never persisted: it expires.
    let url: URL
    let createdAt: Date

    /// The size as the sheet states it, "2,4 Mo".
    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

extension BeverageAttachment {
    init?(fields: VinariumGraphQL.BeverageAttachmentFields) {
        guard let url = URL(string: fields.url) else { return nil }
        self.id = fields.id
        self.kind = Kind(rawValue: fields.kind.rawValue) ?? .document
        self.fileName = fields.fileName
        self.contentType = fields.contentType
        self.size = fields.size
        self.url = url
        self.createdAt = GraphQLHelpers.parseISO8601(fields.createdAt) ?? Date()
    }
}
