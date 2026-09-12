// @generated
// This file was automatically generated and can be edited to
// implement advanced custom scalar functionality.
//
// Any changes to this file will not be overwritten by future
// code generation execution.

@_spi(Internal) @_spi(Execution) import ApolloAPI

extension VinariumGraphQL {
  /// The unique identifier of an `Attachment`, formatted as a UUID v4.
  ///
  /// Handed out when an upload slot is reserved, then used to register or delete the file. Example: "b2f1c0de-7a44-4e1b-9c3f-6d0a1f7e2b55".
  typealias AttachmentId = String

}