import SwiftUI

/// A wine's drinking window as the Weather app draws a day's temperatures: a
/// faint rail from a little before the window to a little after, the window
/// itself in a solid stroke, a dot for today. Above it, its title; below it,
/// the window's first and last years under its two ends. One tint only.
struct DrinkingWindowRail: View {
    struct Window: Equatable {
        let from: Int
        let until: Int
    }

    let window: Window
    var now: Date = .now

    /// The window takes the middle two thirds of the rail.
    private static let start: CGFloat = 1 / 6
    private static let end: CGFloat = 5 / 6

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Garde")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            rail
                .frame(height: 12)
                .padding(.top, 6)
            years
                .padding(.top, 3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Garde"))
        .accessibilityValue(Text("De \(String(window.from)) à \(String(window.until))"))
    }

    /// Where today falls on the rail, the window running from the first day of
    /// its first year to the last day of its last.
    private var today: CGFloat {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let day = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        let days = calendar.range(of: .day, in: .year, for: now)?.count ?? 365
        let position = Double(year) + Double(day - 1) / Double(days)
        let length = Double(window.until + 1 - window.from)
        let fraction = (position - Double(window.from)) / length
        return min(max(Self.start + (Self.end - Self.start) * fraction, 0), 1)
    }

    private var rail: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.12))
                    .frame(height: 4)
                Capsule()
                    .fill(Color.primary.opacity(0.85))
                    .frame(width: width * (Self.end - Self.start), height: 4)
                    .offset(x: width * Self.start)
                Circle()
                    .strokeBorder(Color.primary, lineWidth: 3)
                    .background(Circle().fill(Color(.systemBackground)))
                    .frame(width: 12, height: 12)
                    .offset(x: width * today - 6)
            }
            .frame(height: 12)
        }
    }

    private var years: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .topLeading) {
                yearLabel(window.from).position(x: width * Self.start, y: 8)
                yearLabel(window.until).position(x: width * Self.end, y: 8)
            }
        }
        .frame(height: 16)
    }

    private func yearLabel(_ year: Int) -> some View {
        Text(verbatim: String(year))
            .font(.system(size: 12))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .fixedSize()
    }
}

#Preview {
    VStack(spacing: 28) {
        DrinkingWindowRail(window: .init(from: 2024, until: 2027))
        DrinkingWindowRail(window: .init(from: 2028, until: 2035))
        DrinkingWindowRail(window: .init(from: 2018, until: 2026))
        DrinkingWindowRail(window: .init(from: 2019, until: 2024))
    }
    .padding()
    .frame(width: 290)
}
