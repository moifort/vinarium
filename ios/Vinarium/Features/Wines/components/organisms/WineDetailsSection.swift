import SwiftUI

struct WineDetailsSection: View {
    let alcoholContent: Double?
    let purchasePrice: Double?
    let purchaseDate: String?
    let grapeVarieties: [String]

    var body: some View {
        if alcoholContent != nil || purchasePrice != nil || purchaseDate != nil || !grapeVarieties.isEmpty {
            Section("D\u{00E9}tails") {
                if let alcohol = alcoholContent {
                    LabeledInfoRow(title: "Alcool", value: String(format: "%.1f %% vol", alcohol), icon: "drop")
                }
                if let price = purchasePrice {
                    LabeledInfoRow(title: "Prix d'achat", value: Money.formattedFromEur(price, fractionLength: 0), icon: "eurosign.circle")
                }
                if let date = purchaseDate {
                    LabeledInfoRow(title: "Date d'achat", value: date, icon: "calendar.badge.clock")
                }
                if !grapeVarieties.isEmpty {
                    LabeledInfoRow(title: "C\u{00E9}pages", value: grapeVarieties.joined(separator: " \u{2022} "), icon: "leaf")
                }
            }
        }
    }
}

#Preview {
    List {
        WineDetailsSection(
            alcoholContent: 13.5,
            purchasePrice: 45,
            purchaseDate: "12/2023",
            grapeVarieties: ["Cabernet Sauvignon", "Merlot", "Syrah", "Zinfandel", "Grenache"]
        )
    }
}
