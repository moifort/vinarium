import SwiftUI

struct InteractiveStarRating: View {
    @Binding var rating: Int
    var total: Int = 5

    var body: some View {
        HStack(spacing: 12) {
            ForEach(1...total, id: \.self) { star in
                Button {
                    rating = star == rating ? 0 : star
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundStyle(star <= rating ? .yellow : .gray.opacity(0.4))
                        .font(.title)
                        .scaleEffect(star == rating ? 1.15 : 1.0)
                        .animation(.spring(duration: 0.2), value: rating)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("star-rating-\(star)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Note : \(rating) sur \(total)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if rating < total { rating += 1 }
            case .decrement: if rating > 0 { rating -= 1 }
            @unknown default: break
            }
        }
    }
}

#Preview {
    @Previewable @State var rating = 3
    InteractiveStarRating(rating: $rating)
}
