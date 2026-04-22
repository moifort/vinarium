import SwiftUI

struct GradientWidget: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    var backgroundImage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.9))

            Spacer()

            Text(value)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Spacer()

            HStack(alignment: .bottom) {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
                    .accessibilityHidden(true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .background {
            if let bg = backgroundImage {
                Image(bg)
                    .resizable()
                    .scaledToFill()
                    .overlay(Color.black.opacity(0.4))
            } else {
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .clipShape(.rect(cornerRadius: 20))
    }
}

#Preview {
    HStack(spacing: 12) {
        GradientWidget(
            title: "En cave",
            value: "12",
            subtitle: "Bouteilles",
            icon: "wineglass",
            gradient: [Color(red: 0.55, green: 0.25, blue: 0.8), Color(red: 0.75, green: 0.45, blue: 0.95)]
        )
        GradientWidget(
            title: "Valeur",
            value: "450 \u{20AC}",
            subtitle: "Total",
            icon: "eurosign.circle",
            gradient: [Color(red: 0.15, green: 0.65, blue: 0.45), Color(red: 0.3, green: 0.8, blue: 0.55)]
        )
    }
    .frame(height: 140)
    .padding()
}
