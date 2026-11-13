---
name: ios-feature
description: Use when adding or changing an iOS screen or feature in a Polyforms SwiftUI app (screen, page, organism, ViewModel, client, API, fixtures, previews, tests), or taking its screenshot. The long form of stack rule 10-ios.
---

# Add an iOS feature

`Features/Settings/` is the reference: copy its shape.

## Files

```
Features/<Domain>/
  <Feature>Screen.swift       connected: ViewModel, tasks, change notices, navigation, sheets
  <Feature>ViewModel.swift    @MainActor @Observable, init(client:), state private(set)
  <Domain>Client.swift        struct of @Sendable closures, .live and .preview
  <Domain>API.swift           the only file that sees <App>GraphQL types; returns app models
  <Domain>Models.swift        Sendable app models
  <Domain>Fixtures.swift      static let preview data, shared by previews and tests
  GraphQL/<Domain>.graphql    operations
  components/organisms/       sections, rows, cards: may take a model, map to primitives
  components/pages/           whole screens, pure, one onAction over an enum
```

## The page and its screen

```swift
enum OrdersAction { case open(Order.ID); case delete(Order.ID); case refresh }

struct OrdersPage: View {
    let orders: [Order]
    let isLoading: Bool
    let errorMessage: String?
    let onAction: (OrdersAction) async -> Void
    var body: some View { /* list, EmptyState, EmptyState.failure, .refreshable */ }
}

struct OrdersScreen: View {
    @State private var viewModel = OrdersViewModel(client: .live)
    @State private var opened: Order.ID?
    var body: some View {
        OrdersPage(orders: viewModel.orders, isLoading: viewModel.isLoading,
                   errorMessage: viewModel.errorMessage) { action in
            switch action {
            case let .open(id): opened = id
            case let .delete(id): await viewModel.delete(id)
            case .refresh: await viewModel.load()
            }
        }
        .task { await viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .dataDidChange)) { _ in
            Task { await viewModel.load() }
        }
    }
}
```

## Loading rules in code

- Nothing yet: `ProgressView()` in the body. Failure over nothing: `EmptyState.failure`.
  Failure over rows: keep the rows, `reportError` only.
- Every mutation through `GraphQLHelpers.perform` (it posts `.dataDidChange`); a mutation
  that changes nothing a list shows passes `changesData: false`.
- A button that waits: `AsyncButton` / `AsyncToolbarButton`.
- Lists: `CursorPage`, a `LoadMoreRow`-style closer, a generation token in the ViewModel.

## Screen patterns

The shapes every app repeats, so they are not re-explained per project. Code in the app's
`Shared/Components/`.

**A list row.** Image or icon on the left; the text block **top-aligned** beside it: title, one
secondary line, at most one tag; a status tag in the top corner when the list is not already
sectioned by it. The whole row opens the detail page. The one frequent action is a swipe action;
the context menu mirrors the detail page's menu. A row never carries more than three pieces of
information below its title: the rest belongs to the detail page.

**A detail page (fiche).** Opened from a row as a sheet, or pushed when it is the tab's own
object. From top to bottom: a header section (image, title, one line under it, the state), the
facts as labelled rows with an icon (long press copies the value), the long text, the actions
that belong to the object. **The toolbar**: close (`xmark`) on the left; on the right, the one
action the person takes over and over as its own icon (a favourite heart, a check), then a `…`
menu with the rest, edit first, delete last and red. A single fact is edited **inline in its
row** (tap, type, done), never through a form; the full edit form is one sheet from the menu.
Only known fields are drawn: an absent fact has no row, not an empty one.

**A tab's main screen.** Large title, icon-only actions on the right (add, filter, settings),
search attached to the list when there is one, sections with plain headers, the empty state
drawn in the list body with the one action that fills it.

**A form or a sheet that asks something.** Cancel (`xmark`) left, confirm (`checkmark`) right as
an `AsyncToolbarButton`; the first field focused on appear; a picker shows its current value in
its row; destructive confirmation as a dialog, never a toggle.

## Scrolling performance

Scrolling holds on the oldest supported iPhones, as Apple's own apps do.

- GPU and main-thread cost is a budget on every scrolled screen: no live blur, mask or shadow per
  cell; compute such effects once (a baked image) and reuse it.
- Never put a per-frame scroll value in a page's `@State`: it rebuilds the page on every frame.
  Use an `@Observable` read only by a small modifier.
- Hitches are measured on a phone, in Release, never judged on the simulator: a temporary UI test
  measuring `XCTOSSignpostMetric.scrollingAndDecelerationMetric`, with slow finger-like drags
  (about 220 pt/s) as well as fast swipes. When the tests look clean and the person still feels
  lag, a Release build with a frame probe (a `CADisplayLink` logging frame deltas) finds it.
  Compare runs minutes apart, never an hour apart: the device heats and drifts.
- Say plainly when old phones were not measured.

## Strings

Written in French in the code. After the build: `bun run ios:strings -- --write`, fill the
English of each new key in `Localizable.xcstrings`, rerun without `--write` until it reports
every string translated, commit the catalogue with the code.

## Tests

`<App>Tests/<Domain>/<Feature>ViewModelTests.swift` with Swift Testing: the client built
inline from `.preview` with one closure overridden; `Boom`, `Flag`, `Calls` from
`Support/TestDoubles.swift`. Never a test of a `body`.

## Screenshot

1. A temporary launch argument in `App.swift` that shows the page with its fixtures
   (`if CommandLine.arguments.contains("-shot-orders") { OrdersPage(orders: Order.previews, ...) }`).
2. Build into the default derived data, or the worktree's fixed one, never a new path per
   build (stack rule 15-tooling, Derived data and disk), with `SWIFT_ENABLE_EXPLICIT_MODULES=NO`
   if Sentry's import fails; install on the reference simulator, launch with the argument,
   `xcrun simctl io <udid> screenshot`.
3. Revert the harness before the commit; keep fixtures and previews.
4. Check the design conventions, send the screenshot, wait for approval.

Then `bun run ios:components` (pure and previewed) and `bun run ios:test`.
