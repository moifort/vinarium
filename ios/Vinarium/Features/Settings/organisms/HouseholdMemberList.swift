import SwiftUI

/// The members of a household, each with an owner crown and a "moi" marker. When
/// the viewer is the owner, other members get a remove button. Primitive-first:
/// it takes plain Item structs and a remove closure keyed by userId.
struct HouseholdMemberList: View {
    struct Item: Identifiable, Hashable {
        let userId: String
        let name: String
        let isOwner: Bool
        let isMe: Bool
        var id: String { userId }
    }

    let items: [Item]
    let canRemove: Bool
    let onRemove: (_ userId: String) -> Void

    var body: some View {
        ForEach(items) { item in
            HStack(spacing: 12) {
                Image(systemName: item.isOwner ? "crown.fill" : "person.fill")
                    .foregroundStyle(item.isOwner ? .orange : .secondary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name)
                    if item.isMe {
                        Text("Vous").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if canRemove && !item.isMe {
                    Button(role: .destructive) {
                        onRemove(item.userId)
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
}

#Preview {
    Form {
        Section("Membres du foyer") {
            HouseholdMemberList(
                items: [
                    .init(userId: "1", name: "Thibaut", isOwner: true, isMe: true),
                    .init(userId: "2", name: "Marie", isOwner: false, isMe: false),
                ],
                canRemove: true,
                onRemove: { _ in }
            )
        }
    }
}
