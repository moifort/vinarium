import SwiftUI

/// The row that leads a screen which is already readable while it is being brought up
/// to date — a list or a scrolling page: what is below stays in place and this one
/// spins, the same circle a pull-to-refresh draws, on the screen's own background. What
/// a snapshot shows instead of a loader taking the screen away from what it already
/// has. The list-row modifiers are simply ignored outside a `List`.
///
/// The mirror of `LoadMoreRow`, which closes the list, with one difference: it never
/// starts the work itself. The refresh is already in flight by the time the row
/// appears, so a `.task` here would fetch the same page twice. It becomes a retry
/// button when that refresh failed — otherwise nothing on screen would say the rows
/// are the ones from last time.
struct RefreshRow: View {
    let failed: Bool
    let loadingLabel: LocalizedStringKey
    let onRetry: () async -> Void

    var body: some View {
        HStack {
            Spacer()
            if failed {
                Button {
                    Task { await onRetry() }
                } label: {
                    Label("Réessayer", systemImage: "arrow.clockwise")
                }
                .accessibilityIdentifier("refresh-retry")
            } else {
                ProgressView()
                    .accessibilityLabel(loadingLabel)
                    .accessibilityIdentifier("refresh-spinner")
            }
            Spacer()
        }
        // The pull-to-refresh circle sits on the list's background, not on a card: a
        // plain row would give this one the height and the fill of a wine.
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 6, trailing: 0))
        .listRowSeparator(.hidden)
    }
}

#Preview("Refreshing") {
    List {
        RefreshRow(failed: false, loadingLabel: "Mise à jour de la liste", onRetry: {})
        Section("2018") {
            Text("Château La Sauvageonne")
            Text("Pouilly-Fumé")
        }
    }
}

#Preview("Failed") {
    List {
        RefreshRow(failed: true, loadingLabel: "Mise à jour de la liste", onRetry: {})
        Section("2018") {
            Text("Château La Sauvageonne")
            Text("Pouilly-Fumé")
        }
    }
}
