import SwiftUI

/// The colours a wine's sheet opens on, after the wine: deep red and plum for a red,
/// old gold for a white, salmon for a rosé, amber for what is not wine. They run up
/// under the toolbar and melt into the page under the hero, as the TV app opens a film
/// over its own colours. The hero's text is white whatever the device's appearance:
/// the top of the backdrop stays dark in both.
struct WineSheetBackdrop: View {
    let tone: WineSheetTone
    /// How far the colours run before they are gone.
    var height: CGFloat = 760

    var body: some View {
        ZStack {
            LinearGradient(colors: tone.ground, startPoint: .top, endPoint: .bottom)
            ForEach(Array(tone.glows.enumerated()), id: \.offset) { _, glow in
                Circle()
                    .fill(glow.color)
                    .frame(width: glow.size, height: glow.size)
                    .position(x: glow.x, y: glow.y)
                    .blur(radius: 52)
            }
        }
        .frame(height: height)
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.52),
                    .init(color: .black.opacity(0.45), location: 0.78),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        // One flat image, composed once: the blur is not redrawn as the page scrolls.
        .drawingGroup()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The wine's own colours, for its sheet: the backdrop's ground and glows, and the
/// accent that marks its slot and its drinking window.
enum WineSheetTone {
    case red, white, rosé, other

    init(beverageType: BeverageType, color: WineColor?) {
        guard beverageType == .wine else { self = .other; return }
        self = switch color {
        case .white: .white
        case .rosé: .rosé
        case .red, nil: .red
        }
    }

    struct Glow {
        let color: Color
        let size: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    var ground: [Color] {
        switch self {
        case .red: [Color(hex: 0x2B0618), Color(hex: 0x521030), Color(hex: 0x742244)]
        case .white: [Color(hex: 0x2A1E06), Color(hex: 0x4F3A0E), Color(hex: 0x7A5A1C)]
        case .rosé: [Color(hex: 0x3A0F1C), Color(hex: 0x6E2A3E), Color(hex: 0x9A4A5A)]
        case .other: [Color(hex: 0x2A1606), Color(hex: 0x4E2C0E), Color(hex: 0x76461C)]
        }
    }

    var glows: [Glow] {
        let (a, b, c): (UInt32, UInt32, UInt32) = switch self {
        case .red: (0xC42C60, 0x6A30A0, 0xCE6854)
        case .white: (0xC89A2E, 0x7A6A2A, 0xE0B060)
        case .rosé: (0xE0607E, 0x9A4A8A, 0xF09080)
        case .other: (0xC0702A, 0x7A3A20, 0xE0A050)
        }
        return [
            Glow(color: Color(hex: a).opacity(0.72), size: 400, x: 90, y: 320),
            Glow(color: Color(hex: b).opacity(0.62), size: 340, x: 360, y: 90),
            Glow(color: Color(hex: c).opacity(0.5), size: 340, x: 310, y: 580),
        ]
    }

    /// The colour that marks the wine's slot and where its window stands.
    var accent: Color {
        switch self {
        case .red: Color(light: 0xA3122F, dark: 0xFF6B7D)
        case .white: Color(light: 0x9A6B00, dark: 0xF2C14E)
        case .rosé: Color(light: 0xC23B65, dark: 0xFF8FAB)
        case .other: Color(light: 0xA1501A, dark: 0xF0A050)
        }
    }
}

#Preview("Red") {
    ScrollView {
        WineSheetBackdrop(tone: .red)
    }
    .background(Color(.systemGroupedBackground))
    .ignoresSafeArea()
}

#Preview("White") {
    WineSheetBackdrop(tone: .white)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea()
}
