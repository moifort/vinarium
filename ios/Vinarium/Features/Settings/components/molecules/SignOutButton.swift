import SwiftUI

struct SignOutButton: View {
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            HStack {
                Spacer()
                Label("Se déconnecter", systemImage: "rectangle.portrait.and.arrow.right")
                Spacer()
            }
        }
    }
}

#Preview {
    List {
        SignOutButton(action: {})
    }
}
