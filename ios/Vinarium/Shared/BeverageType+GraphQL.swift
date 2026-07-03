import Apollo
import Foundation

// Single mapping point between the GraphQL wire values and the app enum.
// Unknown values fall back to .other so a new server-side type never crashes the app.
extension BeverageType {
    init(graphql: GraphQLEnum<VinariumGraphQL.BeverageType>) {
        switch graphql {
        case .case(let value):
            switch value {
            case .wine: self = .wine
            case .spirit: self = .spirit
            case .beer: self = .beer
            case .sake: self = .sake
            case .cider: self = .cider
            case .other: self = .other
            }
        case .unknown:
            self = .other
        }
    }

    var graphQLValue: GraphQLEnum<VinariumGraphQL.BeverageType> {
        switch self {
        case .wine: .case(.wine)
        case .spirit: .case(.spirit)
        case .beer: .case(.beer)
        case .sake: .case(.sake)
        case .cider: .case(.cider)
        case .other: .case(.other)
        }
    }
}
