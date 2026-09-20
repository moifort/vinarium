import SwiftUI

/// The one screen that earns the branded loader: the wait between launching the
/// app and the first screen being ready. It is the only place the swirling wine
/// glass appears — every other wait, however long, uses the system spinner
/// through `LoadingStateView`, so the animation stays an opening and never
/// becomes the app's way of saying "busy".
struct LaunchLoadingView: View {
    var label: LocalizedStringKey = "Chargement..."

    var body: some View {
        VStack(spacing: 20) {
            WineGlassLoader()
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LaunchLoadingView()
}
