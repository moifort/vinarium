import SwiftUI

struct WineDetailHeader: View {
    var beverageType: BeverageType = .wine
    let color: WineColor?
    let name: String
    let subtitle: String
    var producerLabel: String = "Domaine"
    let domain: String?
    /// The bottling the producer names on the label. Wine only, hence optional
    /// with no default: the coordinator passes nil for every other beverage.
    var cuvee: String? = nil
    let vintage: Int?
    /// The household member who owns this wine, shown only for a housemate's bottle.
    var ownerName: String? = nil

    var body: some View {
        Section {
            HStack(spacing: 12) {
                BeverageBadge(beverageType: beverageType, color: color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let ownerName {
                LabeledInfoRow(title: "Propri\u{00E9}taire", value: ownerName, icon: "person")
            }
            if let domain {
                LabeledInfoRow(title: "\(producerLabel)", value: domain, icon: "building.2")
            }
            if let cuvee {
                LabeledInfoRow(title: "Cuv\u{00E9}e", value: cuvee, icon: "signature")
            }
            if let vintage {
                LabeledInfoRow(title: "Mill\u{00E9}sime", value: "\(vintage)", icon: "calendar")
            }
        }
    }
}

#Preview {
    List {
        WineDetailHeader(
            color: .red,
            name: "Ch\u{00E2}teau Margaux",
            subtitle: "Rouge \u{2022} Ch\u{00E2}teau Margaux \u{2022} 2018",
            domain: "Ch\u{00E2}teau Margaux",
            cuvee: "Pavillon Rouge",
            vintage: 2018
        )
        WineDetailHeader(
            beverageType: .spirit,
            color: nil,
            name: "Lagavulin 16",
            subtitle: "Spiritueux Single Malt \u{2022} Lagavulin",
            producerLabel: "Distillerie",
            domain: "Lagavulin",
            vintage: nil
        )
    }
}
