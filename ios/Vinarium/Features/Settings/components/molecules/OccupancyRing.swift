import SwiftUI

/// How full a cellar is, drawn as an activity ring: a dimmed track and a
/// wine-coloured arc that closes as bottles are placed.
struct OccupancyRing: View {
    let placed: Int
    let capacity: Int

    @State private var shown: Double = 0

    private static let start = Color(red: 0.50, green: 0.02, blue: 0.16)
    private static let end = Color(red: 0.95, green: 0.22, blue: 0.43)
    private let lineWidth: CGFloat = 16

    private var fraction: Double {
        guard capacity > 0 else { return 0 }
        return min(Double(placed) / Double(capacity), 1)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            ring
                .frame(width: 96, height: 96)
            VStack(alignment: .leading, spacing: 2) {
                Text("Bouteilles placées")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(placed)")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(Self.end)
                        .contentTransition(.numericText())
                    Text("/ \(capacity)")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Bouteilles placées"))
        .accessibilityValue(Text("\(placed) / \(capacity)"))
        .onAppear {
            withAnimation(.spring(duration: 1.0, bounce: 0.2).delay(0.15)) { shown = fraction }
        }
        .onChange(of: fraction) { _, value in
            withAnimation(.spring(duration: 0.6)) { shown = value }
        }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Self.end.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: shown)
                .stroke(
                    AngularGradient(
                        colors: [Self.start, Self.end],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * max(shown, 0.01))
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text(fraction, format: .percent.precision(.fractionLength(0)))
                .font(.system(.headline, design: .rounded, weight: .bold))
                .monospacedDigit()
        }
        .padding(lineWidth / 2)
    }
}

#Preview {
    List {
        OccupancyRing(placed: 0, capacity: 48)
        OccupancyRing(placed: 31, capacity: 48)
        OccupancyRing(placed: 48, capacity: 48)
    }
}
