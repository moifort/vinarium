import SwiftUI

struct ShortlistSection: View {
    let items: [Item]
    var onWineTapped: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("À retenir", systemImage: "bookmark.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if !items.isEmpty {
                    Text("\(items.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if items.isEmpty {
                Text("Aucun vin à retenir")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color(.systemGray6))
                    .clipShape(.rect(cornerRadius: 12))
            } else {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        Button {
                            onWineTapped(item.id)
                        } label: {
                            HStack(spacing: 10) {
                                BeverageBadge(beverageType: item.beverageType, color: item.color)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    HStack(spacing: 4) {
                                        if let vintage = item.vintage {
                                            Text(verbatim: "\(vintage)")
                                        }
                                        if item.vintage != nil, item.tastingDate != nil {
                                            Text("\u{2022}")
                                        }
                                        if let date = item.tastingDate {
                                            Text("Goût\u{00E9} le \(date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year()))")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let rating = item.rating {
                                    StarRatingView(rating: rating)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                        }
                        .tint(.primary)
                    }
                }
                .background(Color(.systemGray6))
                .clipShape(.rect(cornerRadius: 12))
            }
        }
        .accessibilityIdentifier("dashboard-shortlist-section")
    }
}

extension ShortlistSection {
    struct Item: Identifiable {
        let id: String
        var beverageType: BeverageType = .wine
        let color: WineColor?
        let name: String
        let vintage: Int?
        let tastingDate: Date?
        let rating: Int?
    }
}

#Preview("Avec entrées") {
    ShortlistSection(
        items: [
            .init(id: "1", color: .sparkling, name: "Cidre de Normandie", vintage: 2022, tastingDate: Date(), rating: 3),
            .init(id: "2", color: .red, name: "Côtes-du-Rhône", vintage: 2020, tastingDate: nil, rating: 4),
        ],
        onWineTapped: { _ in }
    )
    .padding()
}

#Preview("Vide") {
    ShortlistSection(items: [], onWineTapped: { _ in })
        .padding()
}
