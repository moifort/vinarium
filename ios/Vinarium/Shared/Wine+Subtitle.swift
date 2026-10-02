import Foundation

extension Wine {
    /// Producer shown above the name in the wine list and the global search. Nil when
    /// the name already carries it, case and accents aside: a "Château Margaux" made by
    /// Château Margaux needs no overline repeating it.
    var listDomain: String? {
        guard let domain = domain?.trimmingCharacters(in: .whitespacesAndNewlines),
              !domain.isEmpty else { return nil }
        return name.localizedStandardContains(domain) ? nil : domain
    }

    /// Row subtitle shared by the wine list and the global search: vintage, region,
    /// price, then the related person (gifted by/to, recommended by).
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

    /// "Marie Dupont" becomes "Marie D.", which keeps the subtitle compact.
    static func abbreviated(_ fullName: String) -> String {
        let components = fullName.split(separator: " ")
        if components.count >= 2, let lastInitial = components.last?.first {
            return "\(components.first!) \(lastInitial)."
        }
        return fullName
    }
}
