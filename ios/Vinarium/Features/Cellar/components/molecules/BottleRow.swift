import SwiftUI

struct BottleRow<Title: View, Subtitle: View>: View {
    let beverageType: BeverageType
    let color: WineColor?
    let position: String
    /// The producer, shown above the name; nil when there is none or the name says it.
    let producer: String?
    /// The household member the bottle belongs to; nil for the viewer's own bottles.
    let ownerName: String?
    let title: Title
    let subtitle: Subtitle

    init(
        beverageType: BeverageType = .wine,
        color: WineColor?,
        position: String,
        producer: String? = nil,
        ownerName: String? = nil,
        @ViewBuilder title: () -> Title,
        @ViewBuilder subtitle: () -> Subtitle
    ) {
        self.beverageType = beverageType
        self.color = color
        self.position = position
        self.producer = producer
        self.ownerName = ownerName
        self.title = title()
        self.subtitle = subtitle()
    }

    var body: some View {
        HStack(alignment: .firstLine) {
            BeverageBadge(beverageType: beverageType, color: color)
                .alignmentGuide(.firstLine) { $0[VerticalAlignment.center] }
            VStack(alignment: .leading, spacing: 2) {
                WineRowHeading(producer: producer) {
                    title
                        .font(.headline)
                } marks: {
                    PositionBadge(position: position)
                }
                MemberTagLine(name: ownerName) {
                    subtitle
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension BottleRow where Subtitle == EmptyView {
    init(
        beverageType: BeverageType = .wine,
        color: WineColor?,
        position: String,
        producer: String? = nil,
        ownerName: String? = nil,
        @ViewBuilder title: () -> Title
    ) {
        self.init(
            beverageType: beverageType,
            color: color,
            position: position,
            producer: producer,
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
        BottleRow(color: .white, position: "A2", producer: "Domaine Leflaive") {
            Text("Les Pucelles")
        } subtitle: {
            Text("2019")
        }
        BottleRow(color: .white, position: "B3", ownerName: "Marie") {
            Text("Pouilly-Fume")
        } subtitle: {
            Text("2021")
        }
    }
}
