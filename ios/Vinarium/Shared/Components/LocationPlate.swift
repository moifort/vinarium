import SwiftUI

/// A bottle's slot as the home cards show it: SF Mono bold on a solid plate,
/// set in the card's top trailing corner, like the enamel plate on a rack.
struct LocationPlate: View {
    enum Style {
        /// On the page's own ground: the plate in the text colour, the code in
        /// the background colour.
        case page
        /// On a dark bottle backdrop: a white plate, black code.
        case backdrop
    }

    let position: String
    var style: Style = .backdrop
    /// The cellar the slot belongs to, read out by VoiceOver only.
    var cellarName: String? = nil

    var body: some View {
        Text(verbatim: position)
            .font(.system(size: metrics.size, weight: .bold, design: .monospaced))
            .lineLimit(1)
            .padding(.horizontal, metrics.padding)
            .frame(height: metrics.height)
            .foregroundStyle(style == .page ? Color(.systemBackground) : .black)
            .background(style == .page ? Color.primary : .white, in: .rect(cornerRadius: metrics.radius))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Position \(label)"))
    }

    private var label: String {
        [cellarName, position].compactMap(\.self).joined(separator: " · ")
    }

    private var metrics: (size: CGFloat, height: CGFloat, padding: CGFloat, radius: CGFloat) {
        switch style {
        case .page: (15, 24, 7, 5)
        case .backdrop: (13, 18, 5, 4)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        LocationPlate(position: "B4", style: .page, cellarName: "Entrée")
        LocationPlate(position: "C3")
            .padding()
            .background(Color(red: 0.36, green: 0.09, blue: 0.13))
    }
}
