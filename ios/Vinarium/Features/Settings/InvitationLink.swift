import Foundation

/// Builds the shareable artefacts for a household invitation code: the universal
/// link a guest opens to join, and the e-mail subject/body wrapped around it.
enum InvitationLink {
    /// The universal link that opens the app on `/rejoindre/<CODE>` (and falls back
    /// to the web landing page when the app is not installed).
    static func url(code: String) -> URL {
        // The code alphabet is URL-safe (A–Z, 2–9), so no escaping is needed.
        URL(string: "https://vinarium.app/rejoindre/\(code)")!
    }

    static let mailSubject = "Rejoins ma cave sur Vinarium"

    /// The invitation body used for the mail draft, carrying both the tap-to-join
    /// link and the raw code for anyone who prefers to type it in the app.
    static func mailBody(code: String) -> String {
        """
        Rejoins ma cave sur Vinarium.

        Ouvre ce lien depuis ton iPhone :
        \(url(code: code).absoluteString)

        Ou saisis ce code dans l'app : \(code)
        """
    }
}
