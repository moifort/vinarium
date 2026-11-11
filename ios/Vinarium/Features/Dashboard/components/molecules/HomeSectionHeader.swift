import SwiftUI

/// A home section's title, large and bold, with a chevron when it leads somewhere.
struct HomeSectionHeader: View {
    let title: LocalizedStringKey
    var onTapped: (() -> Void)?

    var body: some View {
        Group {
            if let onTapped {
                Button(action: onTapped) { label }
                    .buttonStyle(.plain)
            } else {
                label
            }
        }
        .padding(.horizontal, 20)
        .accessibilityAddTraits(.isHeader)
    }

    private var label: some View {
        HStack(spacing: 7) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .tracking(-0.3)
            if onTapped != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }
}

/// The wine-coloured haze at the top of the home screen: rosé on the left, old gold
/// on the right, fading into the page's ground as it scrolls away. An empty cellar
/// takes it in purple, deeper, around its turning bottle.
struct HomeAmbience: View {
    enum Tone {
        case wine, purple
    }

    var tone: Tone = .wine

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let (ground, left, right): (Color, Color, Color) = switch tone {
        case .wine: (
            Color(red: 0.47, green: 0.24, blue: 0.28).opacity(0.45),
            Color(red: 0.84, green: 0.47, blue: 0.55).opacity(0.7),
            Color(red: 0.71, green: 0.55, blue: 0.35).opacity(0.55)
        )
        case .purple: (
            Color(red: 0.31, green: 0.05, blue: 0.2).opacity(0.5),
            Color(red: 0.48, green: 0.09, blue: 0.29).opacity(0.78),
            Color(red: 0.36, green: 0.11, blue: 0.41).opacity(0.62)
        )
        }
        ZStack {
            LinearGradient(
                colors: [ground, .clear],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.85)
            )
            EllipticalGradient(
                colors: [left, .clear],
                center: UnitPoint(x: 0.3, y: 0.3),
                startRadiusFraction: 0,
                endRadiusFraction: 0.5
            )
            EllipticalGradient(
                colors: [right, .clear],
                center: UnitPoint(x: 0.8, y: 0.18),
                startRadiusFraction: 0,
                endRadiusFraction: 0.45
            )
        }
        .blur(radius: 30)
        .opacity(colorScheme == .dark ? 1 : 0.8)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview("Header") {
    VStack(spacing: 24) {
        HomeSectionHeader(title: "Activité de la cave", onTapped: {})
        HomeSectionHeader(title: "Mes favoris")
    }
}

#Preview("Ambience") {
    HomeAmbience()
        .frame(height: 760)
        .ignoresSafeArea()
}
