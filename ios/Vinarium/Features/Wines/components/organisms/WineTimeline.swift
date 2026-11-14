import SwiftUI

/// The bottle's life on one thread, the way Wallet follows an order: a disc with a
/// symbol per step, the step in bold with its day and its detail under it, a hairline
/// joining them. The present (today in the cellar, or how the bottle ended) is filled
/// with the wine's accent; what is still to come (the end of its drinking window)
/// sits on a dotted line in a dotted disc. Pure: the screen words the steps.
struct WineTimeline: View {
    let steps: [Step]
    let accent: Color

    struct Step: Identifiable {
        let id: String
        let symbol: String
        /// Already localised.
        let title: String
        var detail: String?
        var state: State = .past

        enum State {
            case past
            case current
            case future
        }
    }

    private static let disc: CGFloat = 32
    private static let veil = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 10 / 255, green: 20 / 255, blue: 36 / 255, alpha: 0.34)
            : UIColor(red: 240 / 255, green: 247 / 255, blue: 1, alpha: 0.36)
    })
    private static let hairline = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.1)
            : UIColor(red: 60 / 255, green: 84 / 255, blue: 130 / 255, alpha: 0.14)
    })

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(steps.indices, id: \.self) { index in
                row(steps[index], next: index + 1 < steps.count ? steps[index + 1] : nil)
            }
        }
    }

    private func row(_ step: Step, next: Step?) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                disc(step)
                if let next {
                    connector(toFuture: next.state == .future)
                }
            }
            .frame(width: Self.disc)

            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: step.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(step.state == .future ? .secondary : .primary)
                if let detail = step.detail {
                    Text(verbatim: detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 1)
            .padding(.bottom, next == nil ? 0 : 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // The thread stretches to the text beside it, never further.
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private func disc(_ step: Step) -> some View {
        let icon = Image(systemName: step.symbol)
            .font(.system(size: 14, weight: .semibold))
            .accessibilityHidden(true)
        switch step.state {
        case .past:
            icon
                .foregroundStyle(.primary)
                .frame(width: Self.disc, height: Self.disc)
                .background {
                    Circle().fill(.ultraThinMaterial).opacity(0.7)
                    Circle().fill(Self.veil)
                }
                .overlay { Circle().strokeBorder(Self.hairline, lineWidth: 1) }
        case .current:
            icon
                .foregroundStyle(.white)
                .frame(width: Self.disc, height: Self.disc)
                .background(Circle().fill(accent))
                .background(Circle().fill(accent.opacity(0.2)).padding(-4))
        case .future:
            icon
                .foregroundStyle(.secondary)
                .frame(width: Self.disc, height: Self.disc)
                .overlay {
                    Circle().strokeBorder(.tertiary, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                }
        }
    }

    @ViewBuilder private func connector(toFuture: Bool) -> some View {
        if toFuture {
            Line()
                .stroke(.tertiary, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                .frame(width: 2)
                .frame(maxHeight: .infinity)
        } else {
            Capsule()
                .fill(Self.hairline)
                .frame(width: 2)
                .frame(maxHeight: .infinity)
        }
    }

    /// A vertical line down the middle of its frame.
    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            }
        }
    }
}

extension WineTimeline.Step {
    static let previewInCellar: [WineTimeline.Step] = [
        .init(id: "acquired", symbol: "gift", title: "Offerte par Julien", detail: "12 sept. 2026 · Valeur 250 €"),
        .init(id: "in-0", symbol: "tray.and.arrow.down", title: "Entrée en cave", detail: "4 oct. 2026 · B3"),
        .init(id: "move-1", symbol: "arrow.left.arrow.right", title: "Déplacée par Marie", detail: "2 nov. 2026 · De B3 vers A1"),
        .init(id: "today", symbol: "clock", title: "Aujourd’hui", detail: "14 nov. 2026 · En cave depuis 41 jours", state: .current),
        .init(id: "window", symbol: "wineglass", title: "Fin de garde", detail: "2040 · Prête à déguster, encore 14 ans", state: .future),
    ]

    static let previewTasted: [WineTimeline.Step] = [
        .init(id: "acquired", symbol: "bag", title: "Achetée", detail: "12 sept. 2026 · 250 €"),
        .init(id: "in-0", symbol: "tray.and.arrow.down", title: "Entrée en cave", detail: "4 oct. 2026 · A1"),
        .init(id: "end", symbol: "wineglass", title: "Dégustée avec Jean et Marie", detail: "8 nov. 2026 · Sortie de A1", state: .current),
    ]
}

#Preview("In cellar") {
    WineTimeline(steps: WineTimeline.Step.previewInCellar, accent: Color(red: 0.64, green: 0.07, blue: 0.18))
        .padding(20)
        .background(Color(.systemGroupedBackground))
}

#Preview("Tasted") {
    WineTimeline(steps: WineTimeline.Step.previewTasted, accent: Color(red: 0.64, green: 0.07, blue: 0.18))
        .padding(20)
        .background(Color(.systemGroupedBackground))
}

#Preview("Largest text") {
    WineTimeline(steps: WineTimeline.Step.previewInCellar, accent: .red)
        .padding(20)
        .environment(\.dynamicTypeSize, .accessibility3)
}
