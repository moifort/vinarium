import MessageUI
import SwiftUI
import UIKit

/// Displays a household invitation code with its expiry and the two sharing
/// gestures — copy the join link, or open a pre-filled mail — plus a revoke
/// action. Leaf view: it owns its share state, the parent runs the revoke.
struct InviteCodeCard: View {
    let code: String
    let expiresAt: Date?
    let onRevoke: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var linkCopied = false
    @State private var showMail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(code)
                .font(.system(.title, design: .monospaced).weight(.bold))
                .tracking(6)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)

            // The API only ever returns still-open codes, so every invitation
            // shown here is pending — the badge is intentionally static.
            Text("En attente")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.15))
                .clipShape(.capsule)
                .frame(maxWidth: .infinity)

            if let expiresAt {
                Text("Valable jusqu'au \(expiresAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }

            HStack {
                Button(action: copyLink) {
                    Label(linkCopied ? "Lien copié" : "Copier le lien",
                          systemImage: linkCopied ? "checkmark" : "link")
                }
                .buttonStyle(.borderless)
                Spacer()
                Button(action: sendMail) {
                    Label("E-mail", systemImage: "envelope")
                }
                .buttonStyle(.borderless)
                Spacer()
                Button("Révoquer", role: .destructive, action: onRevoke)
                    .buttonStyle(.borderless)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showMail) {
            MailComposeView(
                subject: InvitationLink.mailSubject,
                body: InvitationLink.mailBody(code: code)
            ) { showMail = false }
        }
    }

    private func copyLink() {
        UIPasteboard.general.string = InvitationLink.url(code: code).absoluteString
        withAnimation { linkCopied = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { linkCopied = false }
        }
    }

    private func sendMail() {
        if MFMailComposeViewController.canSendMail() {
            showMail = true
        } else if let url = mailtoFallback() {
            openURL(url)
        }
    }

    /// Fallback when no Mail account is configured: hand the invitation to whatever
    /// app registered for `mailto:`.
    private func mailtoFallback() -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.queryItems = [
            URLQueryItem(name: "subject", value: InvitationLink.mailSubject),
            URLQueryItem(name: "body", value: InvitationLink.mailBody(code: code)),
        ]
        return components.url
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
