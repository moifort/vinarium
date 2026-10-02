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
                // The position shares the first line only; the lines below run under
                // it and get the row's full width.
                HStack {
                    if let producer {
                        ProducerOverline(producer: producer)
                    } else {
                        title
                            .font(.headline)
                    }
                    Spacer(minLength: 0)
                    PositionBadge(position: position)
                }
                .alignmentGuide(.firstLine) { $0[VerticalAlignment.center] }
                if producer != nil {
                    title
                        .font(.headline)
                }
                subtitle
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let ownerName {
                    MemberBadge(name: ownerName)
                        .padding(.top, 2)
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
