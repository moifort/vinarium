import SwiftUI

struct ChangelogEntryRow: View {
    let version: String
    let date: Date?
    let summary: String

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(version)
                    .font(.headline)
                Spacer()
                if let date {
                    Text(Self.dateFormatter.string(from: date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    List {
        ChangelogEntryRow(
            version: "2026.04.26",
            date: Date(),
            summary: "Écran Réglages, profil, changelog, cave, import/export."
        )
        ChangelogEntryRow(
            version: "Unreleased",
            date: nil,
            summary: "Modifications en cours."
        )
    }
}
