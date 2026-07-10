import SwiftUI

/// Displays a household invitation code with its expiry, a share sheet and a
/// revoke action. Leaf view: primitives only.
struct InviteCodeCard: View {
    let code: String
    let expiresAt: Date?
    let onRevoke: () -> Void

    private var shareText: String {
        "Rejoins ma cave sur Vinarium avec le code \(code)."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(code)
                .font(.system(.title, design: .monospaced).weight(.bold))
                .tracking(6)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            if let expiresAt {
                Text("Valable jusqu'au \(expiresAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }

            HStack {
                ShareLink(item: shareText) {
                    Label("Partager", systemImage: "square.and.arrow.up")
                }
                Spacer()
                Button("Révoquer", role: .destructive, action: onRevoke)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    Form {
        Section("Invitation") {
            InviteCodeCard(code: "K7P2QM", expiresAt: Date().addingTimeInterval(7 * 86_400)) {}
        }
        Section("Sans expiration") {
            InviteCodeCard(code: "ABC234", expiresAt: nil) {}
        }
    }
}
