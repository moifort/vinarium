import SwiftUI

/// The opening of the app: a wine label in the middle, Vinarium dressed as a
/// château with the app icon for its engraving and a vintage counting up to
/// this year (`WineLabel`), and behind it the surface of red wine seen from
/// very close, folding slowly (`WineSurface`). The label breathes for as long
/// as the launch query runs. `revealing` plays the exit: the label swells and
/// fades, and the wine thins out over the screen already laid out underneath.
///
/// The system launch screen is the bare charcoal; the wine fades in over it.
struct LaunchCurtain: View {
    /// True once what lies behind is ready: plays the exit.
    var revealing: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Anchor for the counter and the breath.
    @State private var start = Date()
    @State private var entered = false
    /// The wine's shader is compiled on the device: it fades in once ready.
    @State private var wineReady = false

    /// The icon's charcoal, the launch screen's `UIColorName` too.
    static let background = Color("LaunchBackground")
    /// Long enough for the vintage to count up and the label to breathe once: a
    /// launch query answered in a hundred milliseconds must not cut the opening.
    static let minimumHold: TimeInterval = 2.4
    /// The vintage the counter starts from, and how long it takes to reach
    /// this year.
    private static let firstVintage = 1945
    private static let countDuration: TimeInterval = 1.6
    private static let breathPeriod: TimeInterval = 2.2

    var body: some View {
        ZStack {
            Self.background
            WineSurface(start: start, moving: !reduceMotion && !revealing) {
                wineReady = true
            }
            // The system launch screen is the bare colour: the wine fades in
            // over it rather than popping.
            .opacity(wineReady ? 1 : 0)
            .animation(.easeOut(duration: 0.8), value: wineReady)
            TimelineView(.animation(paused: revealing || reduceMotion)) { context in
                let time = context.date.timeIntervalSince(start)
                WineLabel(vintage: Self.vintage(time: reduceMotion ? .infinity : time))
                    .scaleEffect(reduceMotion ? 1 : Self.breath(time: time))
            }
            .opacity(entered ? 1 : 0)
            .scaleEffect(entered || reduceMotion ? 1 : 0.9)
            .scaleEffect(revealing && !reduceMotion ? 1.3 : 1)
        }
        .opacity(revealing ? 0 : 1)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.25)) { entered = true }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: "Vinarium"))
        .accessibilityHidden(revealing)
    }

    /// The label's scale at `time`: a slow swell and ease back, once the
    /// vintage has landed.
    private static func breath(time: TimeInterval) -> CGFloat {
        guard time > countDuration else { return 1 }
        let phase = 2 * .pi * (time - countDuration) / breathPeriod
        return 1 + 0.02 * (1 - cos(phase)) / 2
    }

    /// The vintage shown at `time`: from 1945 up to this year, fast then
    /// slowing, the way a counter settles.
    private static func vintage(time: TimeInterval) -> Int {
        let thisYear = Calendar.current.component(.year, from: .now)
        let progress = min(max(time / countDuration, 0), 1)
        let eased = 1 - pow(1 - progress, 3)
        return firstVintage + Int((Double(thisYear - firstVintage) * eased).rounded())
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
