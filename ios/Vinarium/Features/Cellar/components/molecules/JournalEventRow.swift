import SwiftUI

struct JournalEventRow<Title: View>: View {
    let isEntry: Bool
    let position: String
    let title: Title

    init(isEntry: Bool, position: String, @ViewBuilder title: () -> Title) {
        self.isEntry = isEntry
        self.position = position
        self.title = title()
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isEntry ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(isEntry ? .green : .red)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                title
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(isEntry ? "Entrée" : "Sortie")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            PositionBadge(position: position)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    List {
        JournalEventRow(isEntry: true, position: "A1") {
            Text("Chateau Margaux 2018")
        }
        JournalEventRow(isEntry: false, position: "C5") {
            Text("Cotes de Provence 2022")
        }
    }
}
