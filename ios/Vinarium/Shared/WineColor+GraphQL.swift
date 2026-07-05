import Apollo
import Foundation

// Single mapping point between the GraphQL wire values and the app enum.
// Unknown values fall back to .red — centralized here so a future enum change
// only needs one fix.
extension WineColor {
    init(graphql: GraphQLEnum<VinariumGraphQL.WineColor>) {
        switch graphql {
        case .case(let value):
            switch value {
            case .red: self = .red
            case .white: self = .white
            case .rose: self = .rosé
            }
        case .unknown:
            self = .red
        }
    }

    var graphQLValue: GraphQLEnum<VinariumGraphQL.WineColor> {
        switch self {
        case .red: .case(.red)
        case .white: .case(.white)
        case .rosé: .case(.rose)
        }
    }
}
