import SwiftUI

struct JournalSection: View {
    let events: [Event]
    var onEventTapped: (String) -> Void

    var body: some View {
        let lastEntry = events.first { $0.isEntry }
        let lastExit = events.first { !$0.isEntry }

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Journal", systemImage: "book")
                    .font(.headline)
                Spacer()
                if !events.isEmpty {
                    Text("\(events.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if events.isEmpty {
                Text("Aucun \u{00E9}v\u{00E9}nement r\u{00E9}cent")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color(.systemGray6))
                    .clipShape(.rect(cornerRadius: 12))
            } else {
                VStack(spacing: 0) {
                    if let entry = lastEntry {
                        Button { onEventTapped(entry.wineId) } label: {
                            DashboardEventRow(
                                isEntry: true,
                                wineName: entry.wineName,
                                label: "Derni\u{00E8}re entr\u{00E9}e",
                                position: entry.position
                            )
                        }
                        .tint(.primary)
                    }
                    if let exit = lastExit {
                        Button { onEventTapped(exit.wineId) } label: {
                            DashboardEventRow(
                                isEntry: false,
                                wineName: exit.wineName,
                                label: "Derni\u{00E8}re sortie",
                                position: exit.position
                            )
                        }
                        .tint(.primary)
                    }
                }
                .background(Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 12))
            }
        }
    }
}

extension JournalSection {
    struct Event {
        let isEntry: Bool
        let wineName: String
        let position: String
        let wineId: String
    }
}

#Preview("Avec \u{00E9}v\u{00E9}nements") {
    JournalSection(
        events: [
            .init(isEntry: true, wineName: "Ch\u{00E2}teau Margaux 2018", position: "A3", wineId: "1"),
            .init(isEntry: false, wineName: "Pouilly-Fum\u{00E9} 2021", position: "B1", wineId: "2"),
        ],
        onEventTapped: { _ in }
    )
    .padding()
}

#Preview("Vide") {
    JournalSection(events: [], onEventTapped: { _ in })
        .padding()
}
