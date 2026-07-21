import Foundation

/// The two subscriptions sold, as declared in App Store Connect and mirrored in
/// `ios/Vinarium/Vinarium.storekit` for local testing. The identifiers must match all
/// three places exactly — a typo simply makes the product fail to load, silently.
enum SubscriptionProducts {
    static let yearly = "com.polyforms.vinarium.app.premium.yearly"
    static let monthly = "com.polyforms.vinarium.app.premium.monthly"

    /// Yearly first: it is the offer the sheet puts forward.
    static let all = [yearly, monthly]
}
