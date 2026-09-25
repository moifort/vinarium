import SwiftUI

/// The app's full screen loading state: the system spinner and a short caption,
/// centered in all available space. Use it for a view whose content is not ready
/// yet, instead of a bare `ProgressView` pinned inside a list row; small inline
/// waits (buttons, toolbar items, rows) keep the plain spinner with no caption.
///
/// Deliberately the stock iOS indicator: the brand mark animates for the opening
/// alone, in `LaunchCurtain`, and never becomes the app's way of saying "busy".
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
