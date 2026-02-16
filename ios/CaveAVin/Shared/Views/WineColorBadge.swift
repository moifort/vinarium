import SwiftUI

struct WineColorBadge: View {
    let color: WineColor

    var body: some View {
        Circle()
            .fill(color.displayColor.color)
            .frame(width: 12, height: 12)
    }
}
