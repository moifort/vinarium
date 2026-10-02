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

#Preview {
    MemberBadge(name: "Marie")
        .padding()
}
