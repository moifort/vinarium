import SwiftUI

struct WineDetailContent: View {
    let detail: UserWineDetail
    var onRemoveRequested: () -> Void = {}

    var body: some View {
        List {
            WineDetailHeader(
                color: detail.color,
                name: detail.name,
                subtitle: headerSubtitle,
                domain: detail.domain,
                vintage: detail.vintage
            )

            WineOriginSection(
                appellation: detail.appellation,
                region: detail.region,
                country: detail.country,
                classification: detail.classification
            )

            WineDetailsSection(
                alcoholContent: detail.alcoholContent,
                purchasePrice: detail.purchasePrice,
                purchaseDate: detail.purchaseDate,
                grapeVarieties: detail.grapeVarieties
            )

            WineAgingSection(drinkFrom: detail.drinkFrom, drinkUntil: detail.drinkUntil)

            if let cellar = detail.cellar {
                WineCellarSection(
                    position: "\(cellar.row)\(cellar.col)",
                    dateIn: formatted(cellar.dateIn),
                    dateOut: cellar.dateOut.map { formatted($0) },
                    isInCellar: cellar.dateOut == nil,
                    onRemoveRequested: onRemoveRequested
                )
            }

            if let consumption = detail.consumption {
                WineConsumptionSection(
                    consumedDate: consumption.consumedDate.map { formatted($0) },
                    rating: consumption.rating,
                    tastingNotes: consumption.tastingNotes,
                    contacts: consumption.contacts
                )
            }

            if let gift = detail.gift {
                WineGiftSection(giftedDate: formatted(gift.giftedDate), recipientName: gift.recipientName)
            }

            if let giftedBy = detail.giftedBy {
                Section("Offert par") {
                    Label {
                        Text(giftedBy)
                    } icon: {
                        Image(systemName: "gift")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let recommendation = detail.recommendation {
                WineRecommendationSection(
                    recommenderName: recommendation.recommenderName,
                    comment: recommendation.comment
                )
            }

            if let notes = detail.notes, !notes.isEmpty {
                Section("Notes") {
                    Label {
                        Text(notes)
                    } icon: {
                        Image(systemName: "note.text")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var headerSubtitle: String {
        [detail.color.label,
         detail.domain,
         detail.vintage.map { "\($0)" }]
            .compactMap { $0 }
            .joined(separator: " \u{2022} ")
    }

    private func formatted(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}

#Preview("En cave") {
    WineDetailContent(
        detail: UserWineDetail(
            id: "1",
            name: "Château Margaux",
            color: .red,
            domain: "Château Margaux",
            vintage: 2018,
            appellation: "Margaux",
            region: "Bordeaux",
            country: "France",
            grapeVarieties: ["Cabernet Sauvignon", "Merlot"],
            alcoholContent: 13.5,
            classification: "Premier Grand Cru Classé",
            purchasePrice: 350,
            purchaseDate: nil,
            drinkFrom: 2025,
            drinkUntil: 2045,
            notes: "Superbe millésime",
            giftedBy: nil,
            createdAt: Date(),
            updatedAt: Date(),
            cellar: CellarInfo(row: "A", col: 3, dateIn: Date(), dateOut: nil),
            consumption: nil,
            gift: nil,
            recommendation: nil
        ),
        onRemoveRequested: {}
    )
}

#Preview("Consommé") {
    WineDetailContent(
        detail: UserWineDetail(
            id: "2",
            name: "Pouilly-Fumé",
            color: .white,
            domain: nil,
            vintage: 2022,
            appellation: "Pouilly-Fumé",
            region: "Loire",
            country: "France",
            grapeVarieties: ["Sauvignon Blanc"],
            alcoholContent: nil,
            classification: nil,
            purchasePrice: nil,
            purchaseDate: nil,
            drinkFrom: nil,
            drinkUntil: nil,
            notes: nil,
            giftedBy: nil,
            createdAt: Date(),
            updatedAt: Date(),
            cellar: CellarInfo(row: "B", col: 1, dateIn: Date().addingTimeInterval(-86400 * 30), dateOut: Date()),
            consumption: ConsumptionInfo(consumedDate: Date(), rating: 4, tastingNotes: "Très frais, belle minéralité", contacts: ["Jean", "Marie"]),
            gift: nil,
            recommendation: nil
        ),
        onRemoveRequested: {}
    )
}
