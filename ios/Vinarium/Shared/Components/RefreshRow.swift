import SwiftUI

/// The row that leads a screen whose refresh failed while it kept showing what it
/// already had — a list or a scrolling page. A refresh in flight draws nothing: the
/// rows stay put and move into place when the answer lands. Only a failure needs a
/// word, otherwise nothing on screen would say the rows are the ones from last time.
///
/// It never starts the first attempt itself, unlike `LoadMoreRow`: the refresh has
/// already run by the time the row appears. The list-row modifiers are simply ignored
/// outside a `List`.
struct RefreshRow: View {
    let onRetry: () async -> Void

    var body: some View {
        Button {
            Task { await onRetry() }
        } label: {
            Label("Réessayer", systemImage: "arrow.clockwise")
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("refresh-retry")
        // Sits on the list's background, not on a card: a plain row would give this
        // one the height and the fill of a wine.
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 6, trailing: 0))
        .listRowSeparator(.hidden)
    }
}

#Preview {
    List {
        RefreshRow(onRetry: {})
        Section("2018") {
            Text("Château La Sauvageonne")
            Text("Pouilly-Fumé")
        }
    }
}
