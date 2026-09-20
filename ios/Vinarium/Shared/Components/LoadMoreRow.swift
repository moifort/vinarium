import SwiftUI

/// Pagination sentinel row: it triggers the next page load when it appears, and turns
/// into a retry button when the page failed, otherwise the spinner would keep turning
/// forever without a new attempt.
struct LoadMoreRow: View {
    let failed: Bool
    let loadingLabel: LocalizedStringKey
    let onLoadMore: () async -> Void

    var body: some View {
        HStack {
            Spacer()
            if failed {
                Button {
                    Task { await onLoadMore() }
                } label: {
                    Label("Réessayer", systemImage: "arrow.clockwise")
                }
                .accessibilityIdentifier("load-more-retry")
            } else {
                ProgressView()
                    .accessibilityLabel(loadingLabel)
                    .task { await onLoadMore() }
            }
            Spacer()
        }
        // Like `RefreshRow`, the spinner closing the list sits on the list's own
        // background rather than on a card of its own, which would read as one more
        // wine still loading.
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        .listRowSeparator(.hidden)
    }
}

#Preview("Loading") {
    List {
        LoadMoreRow(failed: false, loadingLabel: "Chargement de plus de vins", onLoadMore: {})
    }
}

#Preview("Failed") {
    List {
        LoadMoreRow(failed: true, loadingLabel: "Chargement de plus de vins", onLoadMore: {})
    }
}
