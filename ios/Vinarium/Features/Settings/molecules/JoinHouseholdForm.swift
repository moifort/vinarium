import SwiftUI

/// Code + display-name entry to join an existing household. Leaf view: it owns its
/// own text state and calls back with trimmed values; the parent runs the request.
struct JoinHouseholdForm: View {
    let isWorking: Bool
    let onSubmit: (_ code: String, _ displayName: String) -> Void

    @State private var code = ""
    @State private var displayName: String

    init(
        initialDisplayName: String = "",
        isWorking: Bool,
        onSubmit: @escaping (_ code: String, _ displayName: String) -> Void
    ) {
        self.isWorking = isWorking
        self.onSubmit = onSubmit
        _displayName = State(initialValue: initialDisplayName)
    }

    private var trimmedCode: String { code.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedName: String { displayName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSubmit: Bool { !trimmedCode.isEmpty && !trimmedName.isEmpty && !isWorking }

    var body: some View {
        TextField("Code d'invitation", text: $code)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
        TextField("Votre nom", text: $displayName)
        Button {
            onSubmit(trimmedCode, trimmedName)
        } label: {
            if isWorking {
                ProgressView()
            } else {
                Text("Rejoindre le foyer")
            }
        }
        .disabled(!canSubmit)
    }
}

#Preview {
    Form {
        Section("Rejoindre un foyer") {
            JoinHouseholdForm(initialDisplayName: "Thibaut", isWorking: false) { _, _ in }
        }
    }
}
