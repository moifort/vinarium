// @generated
// This file was automatically generated and can be edited to
// implement advanced custom scalar functionality.
//
// Any changes to this file will not be overwritten by future
// code generation execution.

@_spi(Internal) @_spi(Execution) import ApolloAPI

extension VinariumGraphQL {
  /// What someone types about a bottle, 1 to 300 characters once trimmed.
  ///
  /// On its own it names the beverage for the AI to identify (example: "Grange des Pères 2016 rouge"); sent with a label photo it adds what the label does not show (example: "magnum, bought at the estate").
  typealias BottleDescription = String

}