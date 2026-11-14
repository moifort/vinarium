import SwiftUI

/// The drinking window on glass, as a gauge the way the Watch and Weather draw one:
/// a ring open at the foot, the first and last years at its two ends, the part
/// already behind filled in the wine's colour with a dot on this year, and in its
/// middle the years that are left (or, for a wine too young, the years to wait).
/// Where the wine stands is said in words under it, beside a coloured dot.
struct DrinkingWindowCard: View {
    let from: Int
    let until: Int
    let accent: Color
    var year: Int = Calendar.current.component(.year, from: .now)

    var body: some View {
        let state = DrinkingWindowState(from: from, until: until, year: year)
        VStack(spacing: 0) {
            HStack {
                Text("Garde")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Circle()
                    .fill(state.tint)
                    .frame(width: 8, height: 8)
                    .background(Circle().fill(state.tint.opacity(0.25)).frame(width: 14, height: 14))
                    .accessibilityHidden(true)
            }
            // Centred in the room the title and the words leave it, rather than
            // hung under the title with the gap all below.
            gauge(state)
                .frame(maxHeight: .infinity)
            Text(state.label)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 15)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .glassEffect(.regular, in: .rect(cornerRadius: 26))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("wine-detail-drinking-window")
    }

    /// The ring, 92 points across, open at its foot; the window's first and last
    /// years stand just under its two ends.
    private func gauge(_ state: DrinkingWindowState) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color(.systemFill), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(135))
                Circle()
                    .trim(from: 0, to: 0.75 * state.progress)
                    .stroke(accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(135))
                // This year, on the ring.
                Circle()
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(Circle().strokeBorder(accent, lineWidth: 3.5))
                    .frame(width: 16, height: 16)
                    .offset(x: 46)
                    .rotationEffect(.degrees(135 + 270 * state.progress))
                // The count at the ring's very centre; its unit below, in the
                // opening between the ring's two ends.
                Text(verbatim: "\(state.years)")
                    .font(.system(size: 32, weight: .bold))
                    .monospacedDigit()
                Group {
                    if state.years == 1 { Text("an") } else { Text("ans") }
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .offset(y: 30)
            }
            .frame(width: 92, height: 92)
            HStack {
                Text(verbatim: String(from))
                Spacer()
                Text(verbatim: String(until))
            }
            .font(.caption2.weight(.medium))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .frame(width: 112)
            .padding(.top, -6)
        }
    }
}

/// Where a wine stands in its window this year: too young, ready, or at its end.
struct DrinkingWindowState {
    let progress: Double
    /// The years left before it is ready, or before its window closes.
    let years: Int
    let label: LocalizedStringKey
    let tint: Color

    init(from: Int, until: Int, year: Int) {
        let span = Double(max(until - from, 1))
        progress = min(max(Double(year - from) / span, 0), 1)
        if year < from {
            years = from - year
            label = "Trop jeune"
            tint = Color(.systemOrange)
        } else if year < until {
            years = until - year
            label = "Prêt à déguster"
            tint = Color(.systemGreen)
        } else {
            years = 0
            label = "À boire sans tarder"
            tint = Color(.systemOrange)
        }
    }
}

#Preview("Window") {
    HStack(spacing: 13) {
        DrinkingWindowCard(from: 2025, until: 2040, accent: WineSheetTone.red.accent, year: 2026)
        DrinkingWindowCard(from: 2028, until: 2035, accent: WineSheetTone.white.accent, year: 2026)
    }
    .frame(height: 196)
    .padding(20)
    .background(WineSheetBackdrop(tone: .red))
}

#Preview("Window, at its end") {
    DrinkingWindowCard(from: 2018, until: 2024, accent: WineSheetTone.rosé.accent, year: 2026)
        .frame(width: 170, height: 196)
        .padding(20)
}
