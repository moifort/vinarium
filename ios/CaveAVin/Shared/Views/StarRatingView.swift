import SwiftUI

struct StarRatingView: View {
    let rating: Int
    var total: Int = 5
    var font: Font = .caption2

    var body: some View {
        HStack(spacing: 1) {
            ForEach(1...total, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundStyle(star <= rating ? .yellow : .gray.opacity(0.3))
                    .font(font)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Note : \(rating) sur \(total)")
    }
}

#Preview("Aucune") {
    StarRatingView(rating: 0)
}

#Preview("3 sur 5") {
    StarRatingView(rating: 3)
}

#Preview("5 sur 5") {
    StarRatingView(rating: 5)
}
