import SwiftUI

struct WineGiftSection: View {
    let giftedDate: String
    let recipientName: String?

    var body: some View {
        Section("Offert") {
            Label {
                LabeledContent("Offert le", value: giftedDate)
            } icon: {
                Image(systemName: "gift")
                    .foregroundStyle(.secondary)
            }
            if let recipientName {
                Label {
                    LabeledContent("Destinataire", value: recipientName)
                } icon: {
                    Image(systemName: "person")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    List {
        WineGiftSection(giftedDate: "20 f\u{00E9}vr. 2026", recipientName: "Jean D.")
    }
}
