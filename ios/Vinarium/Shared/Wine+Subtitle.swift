import Foundation

extension Wine {
    /// Row subtitle shared by the wine list and the global search: millésime,
    /// région, prix, puis la personne liée (offert par/à, conseillé par).
    var listSubtitle: String? {
        let parts: [String] = [
            vintage.map { "\($0)" },
            region,
            purchasePrice.map { Money.formattedFromEur($0, fractionLength: 0) },
            giftedBy.map { String(localized: "Offert par \(Self.abbreviated($0))") },
            giftedTo.map { String(localized: "Offert à \(Self.abbreviated($0))") },
            recommendedBy.map { String(localized: "Conseillé par \(Self.abbreviated($0))") },
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }

    /// « Marie Dupont » → « Marie D. » — garde le sous-titre compact.
    static func abbreviated(_ fullName: String) -> String {
        let components = fullName.split(separator: " ")
        if components.count >= 2, let lastInitial = components.last?.first {
            return "\(components.first!) \(lastInitial)."
        }
        return fullName
    }
}
