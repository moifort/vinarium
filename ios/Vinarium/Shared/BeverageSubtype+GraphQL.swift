import Apollo
import Foundation

// Single mapping point between the GraphQL wire values and the app enum.
// An unknown value means the app is older than the server: better no subtype
// than a wrong "Autre" — hence the optional initializer.
extension BeverageSubtype {
    init?(graphql: GraphQLEnum<VinariumGraphQL.BeverageSubtype>) {
        guard case .case(let value) = graphql else { return nil }
        switch value {
        case .sparkling: self = .sparkling
        case .sweet: self = .sweet
        case .lateHarvest: self = .lateHarvest
        case .vinJaune: self = .vinJaune
        case .porto: self = .porto
        case .fortified: self = .fortified
        case .rum: self = .rum
        case .whisky: self = .whisky
        case .gin: self = .gin
        case .vodka: self = .vodka
        case .cognac: self = .cognac
        case .armagnac: self = .armagnac
        case .tequila: self = .tequila
        case .liqueur: self = .liqueur
        case .eauDeVie: self = .eauDeVie
        case .blonde: self = .blonde
        case .blanche: self = .blanche
        case .amber: self = .amber
        case .brune: self = .brune
        case .ipa: self = .ipa
        case .stout: self = .stout
        case .pils: self = .pils
        case .triple: self = .triple
        case .junmai: self = .junmai
        case .ginjo: self = .ginjo
        case .daiginjo: self = .daiginjo
        case .honjozo: self = .honjozo
        case .nigori: self = .nigori
        case .brut: self = .brut
        case .doux: self = .doux
        case .demiSec: self = .demiSec
        case .poire: self = .poire
        case .other: self = .other
        }
    }

    var graphql: GraphQLEnum<VinariumGraphQL.BeverageSubtype> {
        switch self {
        case .sparkling: .case(.sparkling)
        case .sweet: .case(.sweet)
        case .lateHarvest: .case(.lateHarvest)
        case .vinJaune: .case(.vinJaune)
        case .porto: .case(.porto)
        case .fortified: .case(.fortified)
        case .rum: .case(.rum)
        case .whisky: .case(.whisky)
        case .gin: .case(.gin)
        case .vodka: .case(.vodka)
        case .cognac: .case(.cognac)
        case .armagnac: .case(.armagnac)
        case .tequila: .case(.tequila)
        case .liqueur: .case(.liqueur)
        case .eauDeVie: .case(.eauDeVie)
        case .blonde: .case(.blonde)
        case .blanche: .case(.blanche)
        case .amber: .case(.amber)
        case .brune: .case(.brune)
        case .ipa: .case(.ipa)
        case .stout: .case(.stout)
        case .pils: .case(.pils)
        case .triple: .case(.triple)
        case .junmai: .case(.junmai)
        case .ginjo: .case(.ginjo)
        case .daiginjo: .case(.daiginjo)
        case .honjozo: .case(.honjozo)
        case .nigori: .case(.nigori)
        case .brut: .case(.brut)
        case .doux: .case(.doux)
        case .demiSec: .case(.demiSec)
        case .poire: .case(.poire)
        case .other: .case(.other)
        }
    }
}
