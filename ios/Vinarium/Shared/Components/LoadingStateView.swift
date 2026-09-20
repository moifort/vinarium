import SwiftUI

/// The app's full screen loading state: the system spinner and a short caption,
/// centered in all available space. Use it for a view whose content is not ready
/// yet, instead of a bare `ProgressView` pinned inside a list row; small inline
/// waits (buttons, toolbar items, rows) keep the plain spinner with no caption.
///
/// Deliberately the stock iOS indicator: the branded wine glass belongs to the
/// launch alone, in `LaunchLoadingView`.
struct LoadingStateView: View {
    var label: LocalizedStringKey = "Chargement..."

    var body: some View {
        ProgressView(label)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingStateView()
}
