import Foundation

enum TestWineFactory {

    static func redBordeaux() -> [String: Any] {
        [
            "name": "Chateau Test Bordeaux",
            "color": "red",
            "domain": "Chateau Test",
            "vintage": 2020,
            "appellation": "Pauillac",
            "region": "Bordeaux",
            "country": "France",
            "purchasePrice": 25.0,
            "drinkFrom": 2024,
            "drinkUntil": 2030,
        ]
    }

    static func whiteBourgogne() -> [String: Any] {
        [
            "name": "Chablis Test",
            "color": "white",
            "domain": "Domaine Test",
            "vintage": 2022,
            "appellation": "Chablis",
            "region": "Bourgogne",
            "country": "France",
            "purchasePrice": 18.0,
            "drinkFrom": 2023,
            "drinkUntil": 2026,
        ]
    }

    static func roseProvence() -> [String: Any] {
        [
            "name": "Rose Test Provence",
            "color": "rosé",
            "domain": "Domaine Rose",
            "vintage": 2023,
            "appellation": "Cotes de Provence",
            "region": "Provence",
            "country": "France",
            "purchasePrice": 12.0,
        ]
    }

    static func cheapWine(price: Double = 15.0) -> [String: Any] {
        [
            "name": "Vin Test Pas Cher",
            "color": "red",
            "vintage": 2021,
            "region": "Languedoc",
            "purchasePrice": price,
        ]
    }

    static func wineWithVintage(_ vintage: Int, name: String = "Vin Test \(UUID().uuidString.prefix(4))") -> [String: Any] {
        [
            "name": name,
            "color": "red",
            "vintage": vintage,
            "region": "Bordeaux",
        ]
    }
}
