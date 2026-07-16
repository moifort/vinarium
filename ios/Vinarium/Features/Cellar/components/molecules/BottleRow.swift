import SwiftUI

struct BottleRow<Title: View, Subtitle: View>: View {
    let beverageType: BeverageType
    let color: WineColor?
    let position: String
    /// The household member the bottle belongs to; nil for the viewer's own bottles.
    let ownerName: String?
    let title: Title
    let subtitle: Subtitle

    init(
        beverageType: BeverageType = .wine,
        color: WineColor?,
        position: String,
        ownerName: String? = nil,
        @ViewBuilder title: () -> Title,
        @ViewBuilder subtitle: () -> Subtitle
    ) {
        self.beverageType = beverageType
        self.color = color
        self.position = position
        self.ownerName = ownerName
        self.title = title()
        self.subtitle = subtitle()
    }

    var body: some View {
        HStack(alignment: .top) {
            BeverageBadge(beverageType: beverageType, color: color)
            VStack(alignment: .leading, spacing: 2) {
                title
                    .font(.headline)
                subtitle
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let ownerName {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                        Text(ownerName)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
                    .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            PositionBadge(position: position)
        }
    }
}

extension BottleRow where Subtitle == EmptyView {
    init(
        beverageType: BeverageType = .wine,
        color: WineColor?,
        position: String,
        ownerName: String? = nil,
        @ViewBuilder title: () -> Title
    ) {
        self.init(
            beverageType: beverageType,
            color: color,
            position: position,
            ownerName: ownerName,
            title: title
        ) {}
    }
}

#Preview {
    List {
        BottleRow(color: .red, position: "A1") {
            Text("Chateau Margaux")
        } subtitle: {
            Text("2018")
        }
        BottleRow(color: .white, position: "B3", ownerName: "Marie") {
            Text("Pouilly-Fume")
        } subtitle: {
            Text("2021")
        }
    }
}
