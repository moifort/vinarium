import SwiftUI

/// A bare spinner centered in all available space, no caption. Use it as the full
/// screen loading state for a view whose content is not ready yet, instead of a
/// labelled `ProgressView` pinned inside a list row.
struct CenteredProgressView: View {
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CenteredProgressView()
}
