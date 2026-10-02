import SwiftUI

/// Pagination sentinel row: it triggers the next page load when it appears. The list
/// drops it when that page failed, rather than leave a spinner turning forever: a pull
/// reloads the list and brings it back.
struct LoadMoreRow: View {
    let loadingLabel: LocalizedStringKey
    let onLoadMore: () async -> Void

    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .accessibilityLabel(loadingLabel)
                .task { await onLoadMore() }
            Spacer()
        }
        // The spinner closing the list sits on the list's own background rather than
        // on a card of its own, which would read as one more wine still loading.
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        .listRowSeparator(.hidden)
    }
}

#Preview {
    List {
        LoadMoreRow(loadingLabel: "Chargement de plus de vins", onLoadMore: {})
    }
}
