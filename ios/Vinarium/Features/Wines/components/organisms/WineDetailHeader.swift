import SwiftUI

struct WineDetailHeader: View {
    var beverageType: BeverageType = .wine
    let color: WineColor?
    let name: String
    let subtitle: String
    var producerLabel: String = "Domaine"
    let domain: String?
    let vintage: Int?

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

            if let domain {
                LabeledInfoRow(title: producerLabel, value: domain, icon: "building.2")
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
