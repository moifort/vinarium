// @generated
// This file was automatically generated and can be edited to
// implement advanced custom scalar functionality.
//
// Any changes to this file will not be overwritten by future
// code generation execution.

@_spi(Internal) @_spi(Execution) import ApolloAPI

extension VinariumGraphQL {
  /// The opaque identifier of a cellar journal entry, used as a page cursor.
  ///
  /// Read it from `JournalEvents.endCursor` and pass it back as `journalEvents(after:)` to fetch the next page. Example: "Xk3v9Qb2LmT0pR7sYw1a".
  typealias JournalEntryId = String

}