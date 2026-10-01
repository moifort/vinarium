import SwiftUI

/// Which cellar a grid shows, for the screens that place or move a bottle. Only
/// drawn once the household has two cellars. Nil stands for the primary cellar.
struct CellarSwitcher: View {
    let cellars: [CellarSummary]
    @Binding var selection: String?

    var body: some View {
        HStack {
            Label("Cave", systemImage: "square.stack.3d.up")
                .foregroundStyle(.secondary)
            Spacer()
            Picker("Cave", selection: $selection) {
                ForEach(cellars) { cellar in
                    Text(cellar.displayName)
                        .tag(cellar.isPrimary ? String?.none : String?.some(cellar.id))
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("cellar-switcher")
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

#Preview {
    @Previewable @State var selection: String?
    CellarSwitcher(
        cellars: [
            CellarSummary(id: "hh_1", name: nil, isPrimary: true),
            CellarSummary(id: "garage", name: "Garage", isPrimary: false),
        ],
        selection: $selection
    )
}
