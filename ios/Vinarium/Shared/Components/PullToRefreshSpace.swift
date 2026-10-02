import SwiftUI

/// What a screen shows when there is nothing to list: its empty state, or nothing at
/// all when the load failed. A failure is never announced and offers no button — the
/// screen's `.refreshable` is the retry, so this sits in a scroll view the size of the
/// screen, which a pull can always grab.
struct PullToRefreshSpace<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            content
                .containerRelativeFrame([.horizontal, .vertical])
        }
    }
}

extension PullToRefreshSpace where Content == Color {
    /// A blank screen: the load failed and there is nothing from last time to show.
    init() {
        self.init { Color.clear }
    }
}

#Preview("Blank") {
    PullToRefreshSpace()
        .refreshable {}
}

#Preview("Empty state") {
    PullToRefreshSpace {
        ContentUnavailableView("Cave vide", systemImage: "cabinet.fill")
    }
    .refreshable {}
}
