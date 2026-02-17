import SwiftUI

struct WineColorBadge: View {
    let color: WineColor

    var body: some View {
        Circle()
            .fill(color.displayColor.color)
            .overlay(Circle().stroke(.primary.opacity(0.15), lineWidth: 0.5))
            .frame(width: 14, height: 14)
    }
}
