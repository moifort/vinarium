import SwiftUI

/// A form sheet that opens at its `resting` height and rises to full height as
/// soon as one of its fields takes the keyboard, so the keyboard never lands on
/// the text being typed. It stays up once raised: dropping back as the keyboard
/// leaves would jolt the sheet on the way to "Confirmer".
///
/// A multi-line field grows as the user types, and a form does not follow it:
/// the new lines would slide under the keyboard. The row being edited, tagged
/// with `.id(editing)`, is scrolled back into view as its text changes.
private struct KeyboardRaisedDetent<ID: Hashable>: ViewModifier {
    let resting: PresentationDetent
    let editing: ID?
    let text: String

    @State private var detent: PresentationDetent

    init(resting: PresentationDetent, editing: ID?, text: String) {
        self.resting = resting
        self.editing = editing
        self.text = text
        _detent = State(initialValue: resting)
    }

    func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            content
                .presentationDetents([resting, .large], selection: $detent)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: editing) { _, field in
                    guard field != nil else { return }
                    withAnimation(.snappy) { detent = .large }
                }
                .onChange(of: text) {
                    guard let editing else { return }
                    withAnimation(.snappy) { proxy.scrollTo(editing, anchor: .bottom) }
                }
        }
    }
}

extension View {
    /// Presents the sheet at `resting` height, raised to full height while a
    /// field is `editing`, and keeps that field's row (`.id(editing)`) above
    /// the keyboard as `text` grows.
    func keyboardRaisedDetent<ID: Hashable>(
        resting: PresentationDetent,
        editing: ID?,
        text: String
    ) -> some View {
        modifier(KeyboardRaisedDetent(resting: resting, editing: editing, text: text))
    }
}
