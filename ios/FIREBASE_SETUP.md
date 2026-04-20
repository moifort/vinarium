# Firebase + Apollo iOS — manual Xcode setup

The migration to a Firebase backend requires a few one-time Xcode steps that
can't be expressed in source files. Do these once in Xcode, then everything
else (Auth flow, GraphQL client, codegen, feature refactors) is in code.

## 1. Add Swift Package Manager dependencies

`File → Add Package Dependencies…`

| URL | Product(s) | Min version |
| --- | --- | --- |
| `https://github.com/apollographql/apollo-ios.git` | `Apollo`, `ApolloAPI` | 1.18.0 |
| `https://github.com/firebase/firebase-ios-sdk.git` | `FirebaseCore`, `FirebaseAuth` | 11.0.0 |

Both attached to the `CaveAVin` target (Sentry stays on the same target).

## 2. Capabilities

`Target CaveAVin → Signing & Capabilities → + Capability`

- **Sign in with Apple** — required for Apple Sign-In to work with Firebase Auth.

## 3. GoogleService-Info.plist

1. In the Firebase console, register the iOS app (bundle id
   `com.polyforms.cavevin.app`) and download `GoogleService-Info.plist`.
2. Place it at `ios/CaveAVin/GoogleService-Info.plist`. The file is
   gitignored — every developer downloads their own copy.
3. In Xcode, drag-and-drop the file into the `CaveAVin` group so it gets
   added to the bundle (`Copy items if needed: yes`, `Targets: CaveAVin`).

## 4. Apollo iOS codegen

1. Install once globally:
   ```bash
   brew install apollo-ios-cli
   # or: swift package experimental-install apollo-cli
   ```
2. Whenever the GraphQL schema or any operation changes, regenerate:
   ```bash
   # from repo root: regenerate the schema SDL first
   bun run generate:graphql
   # then run the iOS codegen
   cd ios && apollo-ios-cli generate
   ```
3. (Optional) Add an Xcode build phase named "Generate GraphQL" that runs
   `apollo-ios-cli generate` so each build refreshes the typed operations.

## 5. Settings.bundle

The dev/prod URL chooser is no longer needed (the Firebase Functions URL is
deterministic). You can remove `serverURLDev` / `serverURLProd` /
`serverMode` keys from `Settings.bundle/Root.plist`. The cleanup commit
will do this.
