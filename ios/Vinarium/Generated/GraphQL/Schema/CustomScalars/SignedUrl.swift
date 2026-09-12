// @generated
// This file was automatically generated and can be edited to
// implement advanced custom scalar functionality.
//
// Any changes to this file will not be overwritten by future
// code generation execution.

@_spi(Internal) @_spi(Execution) import ApolloAPI

extension VinariumGraphQL {
  /// A time-limited URL, signed by the server for exactly one file.
  ///
  /// An upload URL lasts 15 minutes and expects a `PUT` carrying the exact `Content-Type` it was signed with; a download URL lasts one hour. Neither survives its window, and the bucket is unreachable by any other means.
  typealias SignedUrl = String

}