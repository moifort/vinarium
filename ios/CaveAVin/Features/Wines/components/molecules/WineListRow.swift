import SwiftUI

struct WineListRow: View {
    let color: WineColor
    let name: String
    let subtitle: String?
    let rating: Int?
    let isFavorite: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            WineColorBadge(color: color)
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let rating, !isFavorite {
                StarRatingView(rating: rating)
            }
            if isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                    .font(.default)
                    .frame(alignment: .topLeading)
            }
        }
    }
}

#Preview {
    List {
        WineListRow(
            color: .red,
            name: "Ch\u{00E2}teau Margaux",
            subtitle: "2018 \u{2022} Bordeaux \u{2022} 45 \u{20AC}",
            rating: 4,
            isFavorite: false
        )
        WineListRow(
            color: .white,
            name: "Château La Sauvageonne Cuvée Les Oliviers",
            subtitle: "2021",
            rating: 5,
            isFavorite: true
        )
        WineListRow(
            color: .rosé,
            name: "C\u{00F4}tes de Provence",
            subtitle: nil,
            rating: nil,
            isFavorite: false
        )
    }
}
