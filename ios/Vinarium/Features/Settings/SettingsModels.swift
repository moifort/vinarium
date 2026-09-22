import Foundation

struct ChangelogVersion: Identifiable, Hashable, Sendable {
    let version: String
    let date: Date?
    let notes: [String]
    var id: String { version }
}

struct CellarSettingsInfo: Sendable, Hashable {
    let rows: Int
    let cols: Int
    let zones: Int
    let capacity: Int
    let placedCount: Int
}

/// Outcome of a cellar reconfiguration: either the updated grid, or a refusal
/// carrying how many placed bottles would fall outside the requested dimensions.
enum ReconfigureCellarOutcome: Sendable {
    case success(CellarSettingsInfo)
    case blocked(outOfBounds: Int)
}

struct HouseholdMember: Identifiable, Hashable, Sendable {
    let userId: String
    let displayName: String
    let isOwner: Bool
    let isMe: Bool
    var id: String { userId }
}

struct HouseholdInvite: Identifiable, Hashable, Sendable {
    let code: String
    let expiresAt: Date?
    var id: String { code }
}

struct Household: Sendable, Hashable {
    let members: [HouseholdMember]
    let invitations: [HouseholdInvite]

    var iAmOwner: Bool { members.contains { $0.isMe && $0.isOwner } }

    /// The same household once an invitation was opened or revoked: the mutation
    /// says what changed, so the screen follows without reading the household again.
    func adding(_ invite: HouseholdInvite) -> Household {
        Household(members: members, invitations: invitations + [invite])
    }

    func revoking(_ code: String) -> Household {
        Household(members: members, invitations: invitations.filter { $0.code != code })
    }
}

struct ImportSummary: Sendable, Hashable {
    let wines: Int
    let cellar: Int
    let tasting: Int
    let recommendation: Int
    let gift: Int
    let journal: Int

    var totalRecords: Int {
        wines + cellar + tasting + recommendation + gift + journal
    }
}
