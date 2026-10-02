import SwiftUI

struct WineListRow: View {
    var beverageType: BeverageType = .wine
    let color: WineColor?
    /// The producer, shown above the name like on a merchant's list.
    var domain: String? = nil
    let name: String
    let subtitle: String?
    let rating: Int?
    let isFavorite: Bool
    var isInCellar: Bool = false
    /// The household member this wine belongs to; nil for the viewer's own.
    var ownerName: String? = nil

    var body: some View {
        HStack(alignment: .firstLine) {
            BeverageBadge(beverageType: beverageType, color: color)
                .alignmentGuide(.firstLine) { $0[VerticalAlignment.center] }
            VStack(alignment: .leading, spacing: 2) {
                // The marks share the first line only; the lines below run under
                // them and get the row's full width.
                HStack {
                    if let domain {
                        Text(domain)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        nameText
                    }
                    Spacer(minLength: 0)
                    marks
                }
                .alignmentGuide(.firstLine) { $0[VerticalAlignment.center] }
                if domain != nil {
                    nameText
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let ownerName {
                    MemberBadge(name: ownerName)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var nameText: some View {
        Text(name)
            .font(.headline)
    }

    @ViewBuilder
    private var marks: some View {
        if let rating {
            StarRatingView(rating: rating)
        }
        if isInCellar {
            Image(systemName: "cabinet")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text("En cave"))
        }
        if isFavorite {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
        }
    }
}

private extension VerticalAlignment {
    /// The middle of a row's first line, where the badge sits.
    enum FirstLine: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center]
        }
    }

    static let firstLine = VerticalAlignment(FirstLine.self)
}

#Preview {
    List {
        WineListRow(
            color: .red,
            name: "Ch\u{00E2}teau Margaux",
            subtitle: "2018 \u{2022} Bordeaux \u{2022} 45 \u{20AC}",
            rating: 4,
            isFavorite: false,
            isInCellar: true
        )
        WineListRow(
            color: .white,
            domain: "Domaine Leflaive",
            name: "Les Pucelles",
            subtitle: "2019 \u{2022} Bourgogne \u{2022} 120 \u{20AC}",
            rating: 4,
            isFavorite: false,
            isInCellar: true
        )
        WineListRow(
            color: .white,
            name: "Château La Sauvageonne Cuvée Les Oliviers",
            subtitle: "2021",
            rating: 5,
            isFavorite: true,
            isInCellar: true
        )
        WineListRow(
            color: .red,
            name: "Pauillac Grand Cru",
            subtitle: "2016 \u{2022} Bordeaux",
            rating: 4,
            isFavorite: false,
            isInCellar: true,
            ownerName: "Marie"
        )
        WineListRow(
            beverageType: .cider,
            color: nil,
            name: "Cidre de Normandie",
            subtitle: "Maison Dupont",
            rating: 3,
            isFavorite: true
        )
        WineListRow(
            color: .rosé,
            name: "C\u{00F4}tes de Provence",
            subtitle: nil,
            rating: nil,
            isFavorite: false
        )
        WineListRow(
            beverageType: .beer,
            color: nil,
            name: "La Chouffe",
            subtitle: "Blonde forte \u{2022} Belgique",
            rating: nil,
            isFavorite: false
        )
    }
}
