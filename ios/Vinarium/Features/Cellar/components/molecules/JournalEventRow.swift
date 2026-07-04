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
        // Même recette que les autres rows : icône alignée en haut, colonne texte
        // pleine largeur alignée à gauche, nom tronqué avec ellipsis.
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isEntry ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(isEntry ? .green : .red)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                title
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(isEntry ? "Entrée" : "Sortie")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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
