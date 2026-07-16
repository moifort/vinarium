import SwiftUI

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let tint: Color

    /// Scales with Dynamic Type so the badge always wraps the glyph, which tracks `.body`.
    @ScaledMetric(relativeTo: .body) private var iconBadgeSize: CGFloat = 28

    init(icon: String, title: String, subtitle: String? = nil, tint: Color = .accentColor) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
    }

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: iconBadgeSize, height: iconBadgeSize)
                .background(
                    tint,
                    in: RoundedRectangle(cornerRadius: iconBadgeSize * 6 / 28, style: .continuous)
                )
        }
    }
}

#Preview {
    List {
        SettingsRow(icon: "person.crop.circle", title: "Profil", subtitle: "thibaut@example.com")
        SettingsRow(icon: "doc.text", title: "Changelog", subtitle: "v1.0", tint: .indigo)
        SettingsRow(icon: "square.grid.3x3.fill", title: "Cave", subtitle: "6 \u{00D7} 8", tint: .brown)
        SettingsRow(icon: "square.and.arrow.up", title: "Importer / Exporter", tint: .teal)
        SettingsRow(icon: "person.2.fill", title: "Partage", subtitle: "Bient\u{00F4}t disponible", tint: .gray)
    }
}
