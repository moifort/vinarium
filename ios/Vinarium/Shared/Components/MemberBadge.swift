import SwiftUI

/// The household member behind a bottle or a cellar move. It only shows up for the
/// others: what you did yourself needs no name.
struct MemberBadge: View {
    let name: String

    var body: some View {
        // A small glyph close to its label: at full caption size the person
        // outweighs the name it introduces.
        HStack(spacing: 3) {
            Image(systemName: "person.fill")
                .imageScale(.small)
            Text(name)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

/// A row's last line, the member tag on its own line below it, aligned left.
struct MemberTagLine<Content: View>: View {
    let name: String?
    let content: Content

    init(name: String?, @ViewBuilder content: () -> Content) {
        self.name = name
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            content
            if let name {
                MemberBadge(name: name)
                    .padding(.top, 2)
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        MemberBadge(name: "Marie")
        MemberTagLine(name: "Marie") {
            Text("2022 \u{2022} Bandol")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}
