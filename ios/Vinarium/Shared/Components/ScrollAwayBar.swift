import SwiftUI

/// Whether a bar that scrolls away is called, as Shiori's home bar is: shown at the top of
/// the page, sent away while the reader scrolls down, called back by scrolling up, as Safari
/// brings its bar back. Held in a class and read only by the items that fade: on the page's
/// own state, each call would rebuild the page and every item of the bar.
@MainActor
@Observable
final class ScrollBarState {
    private(set) var isCalled: Bool

    init(isCalled: Bool = true) {
        self.isCalled = isCalled
    }

    func call(_ called: Bool) {
        guard called != isCalled else { return }
        withAnimation(.smooth(duration: 0.25)) { isCalled = called }
    }

    /// Follows the scroll: at the very top, or bouncing above it, the bar shows; scrolling
    /// down sends it away, scrolling up calls it back.
    func follow(from old: CGFloat, to offset: CGFloat) {
        if offset <= 6 {
            call(true)
        } else if offset > old + 4 {
            call(false)
        } else if offset < old - 4 {
            call(true)
        }
    }
}

/// An item of a bar that scrolls away. The item stays in the bar and only fades: taking it
/// out and back would make the system lay the bar out again in the middle of the scroll.
/// Hide the item's shared glass, which would not fade with it, and give it its own, as
/// `ScrollBarButton` does.
struct ScrollBarItem<Content: View>: View {
    let bar: ScrollBarState
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .opacity(bar.isCalled ? 1 : 0)
            .allowsHitTesting(bar.isCalled)
            .accessibilityHidden(!bar.isCalled)
    }
}

/// A round bar button carrying its own glass, 44 points across.
struct ScrollBarButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.medium))
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

/// The page's name on the left of a bar that scrolls away, in Shiori's title size. The page
/// keeps its own `navigationTitle` for VoiceOver and the Back button.
struct ScrollBarTitle: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.title2.weight(.bold))
            .fixedSize()
            .accessibilityHidden(true)
    }
}

#Preview {
    @Previewable @State var bar = ScrollBarState()
    NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(0..<40) { Text(verbatim: "Ligne \($0)") }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { old, offset in
            bar.follow(from: old, to: offset)
        }
        .navigationTitle("Accueil")
        .navigationBarTitleDisplayMode(.inline)
        .scrollEdgeEffectHidden(true, for: .top)
        .toolbar {
            ToolbarItem(placement: .principal) { Text(verbatim: "").accessibilityHidden(true) }
            ToolbarItem(placement: .topBarLeading) {
                ScrollBarItem(bar: bar) { ScrollBarTitle(title: "Accueil") }
            }
            .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .topBarTrailing) {
                ScrollBarItem(bar: bar) {
                    ScrollBarButton(title: "Réglages", systemImage: "gearshape") {}
                }
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }
}
