import SwiftUI

/// Code entry to join an existing household. Leaf view: it owns its code field and
/// calls back with the trimmed value; the name comes from the account (`me.firstName`)
/// and the parent runs the request.
struct JoinHouseholdForm: View {
    let isWorking: Bool
    let onSubmit: (_ code: String) -> Void

    @State private var code = ""

    private var trimmedCode: String { code.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSubmit: Bool { !trimmedCode.isEmpty && !isWorking }

    var body: some View {
        TextField("Code d'invitation", text: $code)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
        Button {
            onSubmit(trimmedCode)
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
            JoinHouseholdForm(isWorking: false) { _ in }
        }
    }
}
