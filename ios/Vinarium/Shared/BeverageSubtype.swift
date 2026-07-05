import Foundation

/// Sous-type structuré d'une boisson (rhum, porto, blonde, junmai…). Un seul
/// enum plat pour tous les types : quelles valeurs un type accepte est porté
/// par `allowed(for:)` — miroir de SUBTYPES_BY_BEVERAGE côté serveur, à garder
/// en phase.
enum BeverageSubtype: String, Codable, CaseIterable, Identifiable, Sendable {
    // vin
    case sparkling
    case sweet
    case lateHarvest = "late-harvest"
    case vinJaune = "vin-jaune"
    case porto
    case fortified
    // spiritueux
    case rum
    case whisky
    case gin
    case vodka
    case cognac
    case armagnac
    case tequila
    case liqueur
    case eauDeVie = "eau-de-vie"
    // bière
    case blonde
    case blanche
    case amber
    case brune
    case ipa
    case stout
    case pils
    case triple
    // saké
    case junmai
    case ginjo
    case daiginjo
    case honjozo
    case nigori
    // cidre
    case brut
    case doux
    case demiSec = "demi-sec"
    case poire
    // tous types
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sparkling: "Pétillant"
        case .sweet: "Moelleux"
        case .lateHarvest: "Vendanges tardives"
        case .vinJaune: "Vin jaune"
        case .porto: "Porto"
        case .fortified: "Vin muté"
        case .rum: "Rhum"
        case .whisky: "Whisky"
        case .gin: "Gin"
        case .vodka: "Vodka"
        case .cognac: "Cognac"
        case .armagnac: "Armagnac"
        case .tequila: "Tequila/Mezcal"
        case .liqueur: "Liqueur"
        case .eauDeVie: "Eau-de-vie"
        case .blonde: "Blonde"
        case .blanche: "Blanche"
        case .amber: "Ambrée"
        case .brune: "Brune"
        case .ipa: "IPA"
        case .stout: "Stout"
        case .pils: "Pils/Lager"
        case .triple: "Triple"
        case .junmai: "Junmai"
        case .ginjo: "Ginjo"
        case .daiginjo: "Daiginjo"
        case .honjozo: "Honjozo"
        case .nigori: "Nigori"
        case .brut: "Brut"
        case .doux: "Doux"
        case .demiSec: "Demi-sec"
        case .poire: "Poiré"
        case .other: "Autre"
        }
    }

    /// Le label du saké pétillant diffère du pétillant vin — la valeur est partagée.
    func label(for beverageType: BeverageType) -> String {
        if self == .sparkling && beverageType == .sake { return "Saké pétillant" }
        return label
    }

    /// Sous-types proposables pour un type de boisson donné.
    static func allowed(for beverageType: BeverageType) -> [BeverageSubtype] {
        switch beverageType {
        case .wine: [.sparkling, .sweet, .lateHarvest, .vinJaune, .porto, .fortified, .other]
        case .spirit: [.rum, .whisky, .gin, .vodka, .cognac, .armagnac, .tequila, .liqueur, .eauDeVie, .other]
        case .beer: [.blonde, .blanche, .amber, .brune, .ipa, .stout, .pils, .triple, .other]
        case .sake: [.junmai, .ginjo, .daiginjo, .honjozo, .nigori, .sparkling, .other]
        case .cider: [.brut, .doux, .demiSec, .poire, .other]
        case .other: [.other]
        }
    }
}
