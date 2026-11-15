import SwiftUI

extension View {
    /// Pushes the screen an item opens on the enclosing stack, as Shiori pushes a
    /// book: the system's Back button closes it, and `onClose` hears it was closed.
    /// What a person opens to look at (a wine) is pushed; what they do (take a
    /// bottle out, edit a wine) stays a sheet.
    func pushesDetail<Item: Identifiable, Destination: View>(
        item: Binding<Item?>,
        onClose: @escaping (Item) -> Void = { _ in },
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) -> some View {
        modifier(PushedDetail(item: item, onClose: onClose, destination: destination))
    }
}

/// The push behind `pushesDetail`. The item last opened stays drawn while the pop
/// animates, once the binding has already let it go.
private struct PushedDetail<Item: Identifiable, Destination: View>: ViewModifier {
    @Binding var item: Item?
    let onClose: (Item) -> Void
    let destination: (Item) -> Destination
    @State private var shown: Item?

    func body(content: Content) -> some View {
        content
            .navigationDestination(isPresented: isPushed) {
                if let opened = item ?? shown {
                    destination(opened)
                }
            }
            .onChange(of: item?.id, initial: true) {
                if let item { shown = item }
            }
    }

    private var isPushed: Binding<Bool> {
        Binding(
            get: { item != nil },
            set: { pushed in
                guard !pushed, let closed = item else { return }
                item = nil
                onClose(closed)
            }
        )
    }
}
