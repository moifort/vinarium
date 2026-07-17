import SwiftUI

/// Le membre du foyer derrière une bouteille ou un mouvement de cave. N'apparaît
/// que pour les autres : ce que l'on fait soi-même n'a pas besoin d'être nommé.
struct MemberBadge: View {
    let name: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.fill")
            Text(name)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.quaternary, in: Capsule())
    }
}

#Preview {
    MemberBadge(name: "Marie")
        .padding()
}
