import SwiftUI

struct LabeledInfoRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        Label {
            LabeledContent(title, value: value)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    List {
        LabeledInfoRow(title: "Appellation", value: "Margaux", icon: "seal")
        LabeledInfoRow(title: "R\u{00E9}gion", value: "Bordeaux", icon: "map")
    }
}
