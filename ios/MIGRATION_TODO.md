# iOS migration — completion checklist

The Firebase backend is fully in place (Nitro + Apollo + Pothos + Firestore,
GraphQL endpoint at `/graphql`, scan IA, migrations, CI deploy). The iOS app
has the new auth flow and the Apollo iOS plumbing, but the per-feature data
APIs still reference the deleted REST clients.

This document lists what remains to do — most of it cannot be expressed in
source until Apollo's Swift codegen has run.

## 1. One-time Xcode setup

See `ios/FIREBASE_SETUP.md` first:
1. Add Apollo iOS + Firebase iOS SDK packages (SPM).
2. Add Sign in with Apple capability.
3. Drop `GoogleService-Info.plist` into `ios/CaveAVin/`.
4. Install `apollo-ios-cli` (`brew install apollo-ios-cli`).

## 2. Generate the Apollo Swift types

```bash
# From the repo root
bun run generate:graphql        # writes shared/schema.graphql

# From the iOS dir
cd ios && apollo-ios-cli generate
```

This populates `ios/CaveAVin/Generated/GraphQL/` with one Swift file per
operation declared under `ios/CaveAVin/Features/{Feature}/GraphQL/*.graphql`,
all in a `CaveAVinGraphQL` namespace.

## 3. Recreate the per-feature APIs as GraphQL

The old REST API files have been removed:
- `ios/CaveAVin/Shared/WineAPI.swift`
- `ios/CaveAVin/Features/Cellar/CellarAPI.swift`
- `ios/CaveAVin/Features/Dashboard/DashboardAPI.swift`
- `ios/CaveAVin/Features/Wines/RecommendationAPI.swift`

ViewModels still call them by name; recreate each enum with the same surface
so the views don't change. Each method becomes a one-liner against
`GraphQLClient.shared.apollo` via `GraphQLHelpers.fetch` / `.perform`, then
maps the codegen output to the existing structs (`Wine`, `UserWineDetail`,
`CellarBottle`, `DashboardData`, `ScanResult`, …).

Example template (Wines list — adapt for each method):

```swift
import Apollo
import Foundation

enum WineAPI {
    static func list(
        color: WineColor? = nil,
        sort: String? = nil,
        order: String? = nil,
        status: String? = nil
    ) async throws -> [Wine] {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: CaveAVinGraphQL.WineListQuery()
        )
        return data.wines.map(mapWine)
    }

    static func getDetail(id: String) async throws -> UserWineDetail {
        let data = try await GraphQLHelpers.fetch(
            GraphQLClient.shared.apollo,
            query: CaveAVinGraphQL.WineDetailQuery(id: id)
        )
        guard let wine = data.wine else { throw APIError.invalidResponse }
        return mapDetail(wine)
    }

    static func create(_ request: CreateWineRequest) async throws -> Wine {
        let input = CaveAVinGraphQL.AddWineInput(
            color: .case(.init(rawValue: request.color.rawValue.uppercased()) ?? .red),
            name: request.name,
            vintage: GraphQLHelpers.graphQLNullable(request.vintage),
            // ...map remaining fields
        )
        let data = try await GraphQLHelpers.perform(
            GraphQLClient.shared.apollo,
            mutation: CaveAVinGraphQL.AddWineMutation(input: input)
        )
        return Wine(
            id: data.addWine.id,
            name: data.addWine.name,
            color: WineColor(rawValue: data.addWine.color.rawValue) ?? .red,
            createdAt: GraphQLHelpers.parseISO8601(data.addWine.createdAt) ?? Date(),
            updatedAt: GraphQLHelpers.parseISO8601(data.addWine.updatedAt) ?? Date()
        )
    }
}
```

The `WineColor` enum on the generated type uses uppercase ASCII values
(`RED`, `WHITE`, `ROSE`, `SPARKLING`, `SWEET`) mapped on the server side to
the internal `'red'|'white'|'rosé'|...`. Map both ways via the rawValue.

### Operations available (cf. `Features/{Feature}/GraphQL/`)

| Feature | Operation | Generated type |
| --- | --- | --- |
| Wines | WineList | `WineListQuery` |
| Wines | WineDetail | `WineDetailQuery` |
| Wines | AddWine | `AddWineMutation` |
| Wines | UpdateWine | `UpdateWineMutation` |
| Wines | DeleteWine | `DeleteWineMutation` |
| Wines | MarkFavorite | `MarkFavoriteMutation` |
| Wines | AddToShortlist | `AddToShortlistMutation` |
| Wines | AddRecommendation | `AddRecommendationMutation` |
| Cellar | CellarBottles | `CellarBottlesQuery` |
| Cellar | CellarHistory | `CellarHistoryQuery` |
| Cellar | SuggestCellarPosition | `SuggestCellarPositionQuery` |
| Cellar | PlaceBottle | `PlaceBottleMutation` |
| Cellar | MoveBottle | `MoveBottleMutation` |
| Cellar | ConsumeBottle | `ConsumeBottleMutation` |
| Cellar | GiftBottle | `GiftBottleMutation` |
| Cellar | RemoveBottle | `RemoveBottleMutation` |
| Dashboard | Dashboard | `DashboardQuery` |
| Scan | ScanWine | `ScanWineMutation` |

## 4. Scan flow change

The scan upload was previously a POST of the JPEG bytes
(`application/octet-stream`). It is now a GraphQL mutation that takes a
base64 string:

```swift
static func scan(imageData: Data) async throws -> ScanResult {
    let base64 = imageData.base64EncodedString()
    let data = try await GraphQLHelpers.perform(
        GraphQLClient.shared.apollo,
        mutation: CaveAVinGraphQL.ScanWineMutation(imageBase64: base64)
    )
    return ScanResult(/* map data.scanWine */)
}
```

Server-side, the cache is keyed by `sha256(buffer)` so the de-dup behavior
across users is preserved.

## 5. UI tests

`CaveAVinUITests/` currently uses `TestAPIClient` with the old REST
endpoints (`/test/reset`, `/wines`, `/cellar/...`) and the static apiToken.
Adapt:
- Point the app at the Firebase Auth + Firestore emulators in launch
  arguments (`Auth.auth().useEmulator(host:port:)`).
- Use the Auth emulator's `/test/__/auth/admin/projects/<id>/accounts`
  endpoint (or directly create a test user with `createUser`).
- Replace `/test/reset` with a Firestore emulator clear (REST DELETE on
  `http://localhost:8080/emulator/v1/projects/<id>/databases/(default)/documents`).

## 6. Final cleanup

Once the new APIs are in place and the app boots:
- Remove this `MIGRATION_TODO.md`.
- Update `ios/FIREBASE_SETUP.md` to reflect the steady state.
- Strip any remaining `import Sentry`-only files if Sentry is dropped.
