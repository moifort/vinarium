import SwiftUI

struct WineDetailHeader: View {
    let color: WineColor
    let name: String
    let subtitle: String
    let domain: String?
    let vintage: Int?

    var body: some View {
        Section {
            HStack(spacing: 12) {
                WineColorBadge(color: color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let domain {
                LabeledInfoRow(title: "Domaine", value: domain, icon: "building.2")
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
    }
}
