import SwiftUI

struct CellarJournalView: View {
    let events: [HistoryEvent]

    private var groupedByDate: [(date: String, events: [HistoryEvent])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let grouped = Dictionary(grouping: events) { event in
            formatter.string(from: event.date)
        }

        return grouped
            .map { (date: $0.key, events: $0.value) }
            .sorted { $0.events[0].date > $1.events[0].date }
    }

    var body: some View {
        if events.isEmpty {
            ContentUnavailableView("Aucun historique", systemImage: "clock", description: Text("L'historique apparaîtra ici"))
        } else {
            List {
                ForEach(groupedByDate, id: \.date) { group in
                    Section(group.date) {
                        ForEach(group.events) { event in
                            eventRow(event)
                        }
                    }
                }
            }
        }
    }

    private func eventRow(_ event: HistoryEvent) -> some View {
        HStack(spacing: 12) {
            Image(systemName: event.type == .entry ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(event.type == .entry ? .green : .red)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.wineName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    WineColorBadge(color: event.wineColor)
                    Text(event.type == .entry ? "Entrée" : "Sortie")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("· \(event.position)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let rating = event.rating {
                HStack(spacing: 1) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundStyle(star <= rating ? .yellow : .gray)
                            .font(.caption2)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}
