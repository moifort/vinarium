import SwiftUI

/// The opening of the app: a wine label in the middle, Vinarium dressed as a
/// château with the app icon for its engraving and this year for its vintage
/// (`WineLabel`), and behind it the surface of red wine seen from very close,
/// folding slowly (`WineSurface`). The label holds still, as on a bottle: all
/// the movement is the wine's, and that is where the eye goes. `revealing`
/// plays the exit: label and wine dissolve where they are, into the screen
/// already laid out underneath.
///
/// The system launch screen is the bare charcoal; the label and the wine fade
/// in over it.
struct LaunchCurtain: View {
    /// True once what lies behind is ready: plays the exit.
    var revealing: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Anchor for the wine's movement.
    @State private var start = Date()
    @State private var entered = false
    /// The wine's shader is compiled on the device: it fades in once ready.
    @State private var wineReady = false

    /// The icon's charcoal, the launch screen's `UIColorName` too.
    static let background = Color("LaunchBackground")
    /// Long enough for the wine to fade in and be seen moving: a launch query
    /// answered in a hundred milliseconds must not cut the opening.
    static let minimumHold: TimeInterval = 2.4

    var body: some View {
        ZStack {
            Self.background
            // Still moving through the exit, so the fade does not freeze it.
            WineSurface(start: start, moving: !reduceMotion) {
                wineReady = true
            }
            // The system launch screen is the bare colour: the wine fades in
            // over it rather than popping.
            .opacity(wineReady ? 1 : 0)
            .animation(.easeOut(duration: 0.8), value: wineReady)
            WineLabel(vintage: Calendar.current.component(.year, from: .now))
                .opacity(entered ? 1 : 0)
        }
        .opacity(revealing ? 0 : 1)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { entered = true }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: "Vinarium"))
        .accessibilityHidden(revealing)
    }
}

#Preview("Opening") {
    LaunchCurtain(revealing: false)
}

#Preview("Revealing") {
    @Previewable @State var revealing = false
    ZStack {
        Text(verbatim: "The app").font(.largeTitle)
        LaunchCurtain(revealing: revealing)
    }
    .onTapGesture {
        withAnimation(.easeInOut(duration: 0.8)) { revealing.toggle() }
    }
}
