import SwiftUI

struct WineConsumptionSection: View {
    let consumedDate: String?
    let rating: Int?
    let tastingNotes: String?
    let contacts: [String]?

    var body: some View {
        Section("Consommé") {
            if let consumedDate {
                Label {
                    LabeledContent("Consommé le", value: consumedDate)
                } icon: {
                    Image(systemName: "fork.knife")
                        .foregroundStyle(.secondary)
                }
            }
            if let rating {
                HStack {
                    Label("Note", systemImage: "star")
                        .foregroundStyle(.secondary)
                    Spacer()
                    StarRatingView(rating: rating, font: .caption)
                }
            }
            if let tastingNotes {
                Label {
                    Text(tastingNotes)
                } icon: {
                    Image(systemName: "note.text")
                        .foregroundStyle(.secondary)
                }
            }
            if let contacts, !contacts.isEmpty {
                Label {
                    Text(contacts.joined(separator: ", "))
                } icon: {
                    Image(systemName: "person.2")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    List {
        WineConsumptionSection(
            consumedDate: "20 févr. 2026",
            rating: 4,
            tastingNotes: "Très bon, tanins souples",
            contacts: ["Jean Dupont", "Marie Martin"]
        )
    }
}
