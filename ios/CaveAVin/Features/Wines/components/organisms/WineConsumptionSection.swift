import SwiftUI

struct WineConsumptionSection: View {
    let consumedDate: String?
    let rating: Int?
    let tastingNotes: String?

    var body: some View {
        Section("Consomm\u{00E9}") {
            if let consumedDate {
                Label {
                    LabeledContent("Consomm\u{00E9} le", value: consumedDate)
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
        }
    }
}

#Preview {
    List {
        WineConsumptionSection(
            consumedDate: "20 f\u{00E9}vr. 2026",
            rating: 4,
            tastingNotes: "Tr\u{00E8}s bon, tanins souples"
        )
    }
}
