import Foundation

/// Attaching a file takes three steps, and the bytes never go through the API:
/// the server signs an upload URL for one object, the phone `PUT`s straight to
/// storage, then the server is told the file landed. Splitting it this way keeps
/// a ten-megabyte photo off the GraphQL endpoint entirely.
enum AttachmentAPI {
    static func upload(
        beverageId: String,
        data: Data,
        fileName: String,
        contentType: String
    ) async throws -> BeverageAttachment {
        let prepared = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.PrepareAttachmentUploadMutation(
                beverageId: beverageId,
                contentType: contentType,
                size: data.count
            )
        ).prepareAttachmentUpload

        guard let uploadURL = URL(string: prepared.uploadUrl) else { throw APIError.invalidResponse }
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        // The signature covers this header. A value that differs at all, even in
        // case, is rejected by the bucket with a 403 that says nothing useful.
        request.setValue(prepared.contentType, forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.upload(for: request, from: data)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw APIError.httpError(http.statusCode) }

        let registered = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.RegisterAttachmentMutation(
                beverageId: beverageId,
                attachmentId: prepared.attachmentId,
                fileName: fileName
            )
        ).registerAttachment

        guard let attachment = BeverageAttachment(fields: registered.fragments.beverageAttachmentFields)
        else { throw APIError.invalidResponse }
        return attachment
    }

    static func delete(attachmentId: String) async throws {
        _ = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: VinariumGraphQL.DeleteAttachmentMutation(attachmentId: attachmentId)
        )
    }

    /// Pull a file down to a temporary location so the document viewer can open
    /// it. The signed URL is short-lived, so the copy is made when it is needed
    /// and left to the system to clean up.
    static func download(_ attachment: BeverageAttachment) async throws -> URL {
        let (temporary, response) = try await URLSession.shared.download(from: attachment.url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.httpError(http.statusCode)
        }
        // QuickLook picks its renderer from the extension, so the file has to
        // carry the real name rather than the random one URLSession hands back.
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(attachment.id, isDirectory: true)
            .appendingPathComponent(attachment.fileName)
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: temporary, to: destination)
        return destination
    }
}
