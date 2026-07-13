# iOS Development Guide

## Tech Stack

- **SwiftUI** with iOS 26.0 deployment target
- **Swift 6** with strict concurrency
- **Apollo iOS** (via SPM) — the app talks to the backend over GraphQL
- **Firebase Auth** — requests carry a Firebase ID token
- **Sentry** for crash reporting and performance monitoring

## Project Structure

```
ios/Vinarium/
├── VinariumApp.swift           # Entry point + Firebase/Sentry init
├── ContentView.swift           # Root view
├── Assets.xcassets/            # App icon, accent color
├── Generated/GraphQL/          # Apollo codegen output (schema types + operations)
├── Shared/
│   ├── APIClient.swift             # Base URL + REST helper
│   ├── GraphQLClient.swift         # Apollo singleton (Firebase Bearer auth)
│   ├── FirebaseTokenInterceptor.swift # Injects Authorization: Bearer <ID token>
│   ├── ErrorReporting.swift        # Sentry error reporting
│   ├── Secrets.swift               # API tokens (gitignored)
│   └── Components/                 # Cross-feature reusable atoms
│       ├── WineColorBadge.swift
│       ├── StarRatingView.swift
│       └── LabeledInfoRow.swift
└── Features/                   # Feature modules
    └── {Feature}/
        ├── {Feature}Models.swift      # Swift model structs (Wine, UserWineDetail …)
        ├── {Feature}API.swift         # Feature API enum (wraps GraphQL operations)
        ├── {Feature}ViewModel.swift   # ViewModel
        ├── GraphQL/                   # .graphql query/mutation operation files
        └── components/
            ├── pages/                 # Coordinators (loading, sheets, navigation)
            ├── organisms/             # Composite sections, forms, content views
            └── molecules/             # Small composed views (rows, badges)
```

Xcode uses `fileSystemSynchronizedGroups`, so new files are picked up automatically — no manual project edits.

## Feature Pattern

### ViewModel

> Every network call shows a loading state (lists, buttons, sections) — never a silent fetch.

```swift
import SwiftUI

@MainActor @Observable
final class WineListViewModel {
    private(set) var wines: [Wine] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let page = try await WineAPI.list(/* … */)
            wines = page.items
        } catch {
            errorMessage = reportError(error)
        }
    }
}
```

Key conventions:
- `@MainActor` on all ViewModels
- `@Observable` (not `ObservableObject`)
- `private(set)` for published state
- Error reporting via `reportError()` (Sentry)

### Page View

```swift
struct WineListPage: View {
    @State private var viewModel = WineListViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.wines) { wine in
                WineListRow(name: wine.name, color: wine.color)
            }
            .navigationTitle("Cave")
            .task { await viewModel.load() }
        }
    }
}
```

### Primitive-First Views

Leaf views (atoms, molecules) receive only primitive types — never domain structs:

```swift
// Good — takes only what it displays
struct WineListRow: View {
    let name: String
    let color: WineColor  // simple enum without logic = tolerated
    let vintage: Int?

    var body: some View {
        HStack {
            WineColorBadge(color: color)
            Text(name)
        }
    }
}

// Bad — takes the full model (many fields, only 3 used)
struct WineListRow: View {
    let wine: Wine  // Don't do this
}
```

**Allowed types in leaf views:**
- `String`, `Int`, `Int?`, `Double?`, `Bool`, `Date?`
- Simple enums without logic (like `WineColor` — equivalent to a typed String)
- Closures (`() -> Void`, `(String) -> Void`)
- **Never** domain structs (`Wine`, `UserWineDetail`, `CellarBottle`)

### Item Pattern (5+ Parameters)

When a component needs more than ~5 parameters, define a nested `Item` struct:

```swift
struct WineListContent: View {
    let items: [Item]

    var body: some View {
        List(items) { item in
            WineListRow(name: item.name, color: item.color, vintage: item.vintage)
        }
    }
}

extension WineListContent {
    struct Item: Identifiable {
        let id: String
        let name: String
        let color: WineColor
        let vintage: Int?
        let isFavorite: Bool
    }
}
```

The mapping from domain models to `Item` happens at the **page level** (coordinator):

```swift
struct WineListPage: View {
    @State private var viewModel = WineListViewModel()

    var body: some View {
        WineListContent(
            items: viewModel.wines.map { wine in
                .init(id: wine.id, name: wine.name, color: wine.color,
                      vintage: wine.vintage, isFavorite: wine.isFavorite)
            }
        )
    }
}
```

### Atomic Design Layers

| Layer | Location | Receives | Examples |
|-------|----------|----------|----------|
| **Atoms** | `Shared/Components/` | Primitives | `WineColorBadge`, `StarRatingView` |
| **Molecules** | `Features/{F}/components/molecules/` | Primitives | `WineListRow`, `LocationSection` |
| **Organisms** | `Features/{F}/components/organisms/` | Primitives or `Item` / domain struct at the mapping boundary | `WineListContent`, `WineEditForm`, `WineDetailContent` |
| **Pages** | `Features/{F}/components/pages/` | ViewModel | `WineListPage`, `WineDetailPage` |

**Atoms** in `Shared/Components/` are cross-feature. A molecule used in 2+ features should be promoted to `Shared/Components/`.

### Page = Coordinator

Pages handle loading, error states, sheets, navigation, and toolbar. They map domain models to primitives for child components. They are the only layer allowed to call APIs and hold `@State` for sheet presentation.

### Organisms as Mapping Boundaries

An organism like `WineDetailContent` can accept a domain struct when it's the **mapping boundary** — the point where the domain model is broken down into primitives for child sections:

```swift
struct WineDetailContent: View {
    let detail: UserWineDetail          // OK at organism level
    var onRemoveRequested: () -> Void = {}

    var body: some View {
        List {
            WineDetailHeader(name: detail.name, color: detail.color)       // primitives
            WineOriginSection(region: detail.region, country: detail.country) // primitives
        }
    }
}
```

The key: child sections within the organism only receive primitives.

### Edit Form Pattern

Extract edit forms into standalone organisms with a `Fields` struct:

```swift
struct WineEditForm: View {
    let initial: Fields
    let onSave: (UpdateRequest) async throws -> Void
    let onCancel: () -> Void

    @State private var name: String
    // … @State per field, initialized from `initial` via State(initialValue:)

    struct Fields {
        var name: String
        var color: WineColor
        // … all primitive values
    }
}
```

Benefits: previewable in isolation, testable independently, the parent page stays lean.

### Previews as Storybook

Every component below the page level **must** be previewable without a running server:

```swift
// Good — preview with inline data
#Preview("En cave") {
    WineDetailContent(detail: UserWineDetail(id: "1", name: "Margaux", /* … */), onRemoveRequested: {})
}

// Bad — preview that hits the API
#Preview {
    WineDetailPage(wineId: "c2f5486a-…")  // needs a server
}
```

Pages (coordinators) are the exception — they load data. But their child organisms/molecules must all be previewable with mock data.

## GraphQL Client (Apollo iOS)

The app talks to the backend over GraphQL only. `GraphQLClient.shared` wraps Apollo's `ApolloClient`, pointed at `<baseURL>/graphql`, with a `FirebaseTokenInterceptor` that injects `Authorization: Bearer <Firebase ID token>` on every request.

Feature APIs are enums that wrap the generated operations and return the app's own model types, so ViewModels never touch Apollo generated types:

```swift
enum WineAPI {
    static func list(/* … */) async throws -> WinePage {
        let query = VinariumGraphQL.WineListQuery(/* … */)
        // execute, then map generated types → Wine
    }
    static func delete(id: String) async throws { /* mutation */ }
}
```

**Architecture:**
- `Shared/GraphQLClient.swift` — the Apollo singleton (Firebase Bearer auth, logging interceptor)
- `Features/{Feature}/{Feature}API.swift` — feature API enum returning app model types
- `.graphql` operation files in `Features/{Feature}/GraphQL/` — queries and mutations
- Generated types in `Generated/GraphQL/` — schema namespace `VinariumGraphQL`

**Codegen:** after changing the server schema, regenerate the SDL (`bun run generate:graphql`), then run `cd ios && apollo-ios-cli generate` (config `ios/apollo-codegen-config.json`). When adding a branded type, also update the custom scalar mapping under `Generated/GraphQL/`.

## Model Types

App model types are plain `Sendable` structs mapped from the GraphQL responses (Swift 6 requires `Sendable`):

```swift
struct Wine: Sendable, Identifiable {
    let id: String
    let name: String
    let color: WineColor
    let vintage: Int?
    // …
}
```

## Secrets Setup

Copy the examples and fill in your values:

```bash
cp ios/Vinarium/Shared/Secrets.swift.example ios/Vinarium/Shared/Secrets.swift
cp ios/VinariumUITests/Support/TestSecrets.swift.example ios/VinariumUITests/Support/TestSecrets.swift
```

## Build

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project ios/Vinarium.xcodeproj -scheme Vinarium \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build
```

`DEVELOPER_DIR` is required because `xcode-select` points to the CommandLineTools. The simulator is iPhone 17, OS 26.2.
