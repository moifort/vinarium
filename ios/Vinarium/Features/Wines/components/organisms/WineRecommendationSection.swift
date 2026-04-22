import SwiftUI

struct WineRecommendationSection: View {
    let recommenderName: String?
    let comment: String?

    var body: some View {
        Section("Conseillé") {
            if let recommenderName {
                Label {
                    LabeledContent("Conseillé par", value: recommenderName)
                } icon: {
                    Image(systemName: "person.badge.star")
                        .foregroundStyle(.secondary)
                }
            } else {
                Label {
                    Text("Vin conseillé")
                } icon: {
                    Image(systemName: "person.badge.star")
                        .foregroundStyle(.secondary)
                }
            }
            if let comment {
                Label {
                    LabeledContent("Commentaire", value: comment)
                } icon: {
                    Image(systemName: "text.quote")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    List {
        WineRecommendationSection(recommenderName: "Marie L.", comment: "Excellent avec du fromage")
    }
}
