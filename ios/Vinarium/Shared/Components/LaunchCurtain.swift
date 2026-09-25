import SwiftUI

/// The opening of the app. The system launch screen shows the whole screen
/// paved with capsules on the icon's charcoal; this view is the first SwiftUI
/// frame, and it draws the very same picture, so the hand-over from the static
/// screen to the running app is invisible. Then the field clears, capsule by
/// capsule, down to the brand mark, which breathes for as long as the launch
/// query runs, the way
/// Uber's mark plays while the map loads behind it. `revealing` plays the
/// exit: the mark swells and fades, and the charcoal thins out over the screen
/// already laid out underneath.
///
/// The launch image, `Resources/LaunchField@{2,3}x.png`, is rendered from `CapsuleField`
/// at `capsuleSize` by `scripts/generate-launch-image.swift`: change one, rerun
/// the other.
struct LaunchCurtain: View {
    /// True once what lies behind is ready: plays the exit.
    var revealing: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Anchor for elapsed time so the opening starts from its still picture.
    @State private var start = Date()

    /// The size the launch image was rendered at.
    static let capsuleSize: CGFloat = 44
    /// The icon's charcoal, the launch screen's `UIColorName` too.
    static let background = Color("LaunchBackground")
    /// Long enough for the field to clear and the mark to breathe once: a
    /// launch query answered in a hundred milliseconds must not cut the opening.
    static var minimumHold: TimeInterval { CapsuleField.clearEnd + 0.6 }

    var body: some View {
        ZStack {
            Self.background
            TimelineView(.animation(paused: revealing)) { context in
                CapsuleFieldView(
                    capsuleSize: Self.capsuleSize,
                    time: context.date.timeIntervalSince(start),
                    motion: !reduceMotion,
                    breathing: !reduceMotion
                )
            }
            .scaleEffect(revealing && !reduceMotion ? 1.6 : 1)
        }
        .opacity(revealing ? 0 : 1)
        .ignoresSafeArea()
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
        withAnimation(.easeIn(duration: 0.5)) { revealing.toggle() }
    }
}
