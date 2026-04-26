import SwiftUI

struct SharingSettingsView: View {
    var body: some View {
        ContentUnavailableView(
            "Partage de cave",
            systemImage: "person.2.fill",
            description: Text(
                "Cette fonctionnalité sera disponible prochainement. Elle permettra de partager la cave avec d'autres utilisateurs tout en conservant des notes personnelles à chacun."
            )
        )
        .navigationTitle("Partage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SharingSettingsView()
    }
}
