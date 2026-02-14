import SwiftUI

struct ServerConfigView: View {
    @State private var urlText = APIClient.shared.baseURL.absoluteString

    var body: some View {
        Form {
            Section("Serveur") {
                TextField("URL du serveur", text: $urlText)
                    .textContentType(.URL)
                    .autocapitalization(.none)
                    .keyboardType(.URL)

                Button("Enregistrer") {
                    if let url = URL(string: urlText) {
                        APIClient.shared.baseURL = url
                    }
                }
            }
        }
        .navigationTitle("Configuration")
    }
}

#Preview {
    NavigationStack {
        ServerConfigView()
    }
}
