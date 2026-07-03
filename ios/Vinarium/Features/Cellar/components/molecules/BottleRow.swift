import SwiftUI

struct BottleRow<Title: View, Subtitle: View>: View {
    let beverageType: BeverageType
    let color: WineColor?
    let position: String
    let title: Title
    let subtitle: Subtitle

    init(
        beverageType: BeverageType = .wine,
        color: WineColor?,
        position: String,
        @ViewBuilder title: () -> Title,
        @ViewBuilder subtitle: () -> Subtitle
    ) {
        self.beverageType = beverageType
        self.color = color
        self.position = position
        self.title = title()
        self.subtitle = subtitle()
    }

    var body: some View {
        HStack {
            BeverageBadge(beverageType: beverageType, color: color)
            VStack(alignment: .leading) {
                title
                    .font(.headline)
                subtitle
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            PositionBadge(position: position)
        }
    }
}

extension BottleRow where Subtitle == EmptyView {
    init(beverageType: BeverageType = .wine, color: WineColor?, position: String, @ViewBuilder title: () -> Title) {
        self.init(beverageType: beverageType, color: color, position: position, title: title) {}
    }
}

#Preview {
    List {
        BottleRow(color: .red, position: "A1") {
            Text("Chateau Margaux")
        } subtitle: {
            Text("2018")
        }
        BottleRow(color: .white, position: "B3") {
            Text("Pouilly-Fume")
        }
    }
}
