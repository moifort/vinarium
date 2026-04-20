# Cave-a-Vin

A purely functional approach to wine cellar management.

<p align="center">
  <img src="screenshots/dashboard.png" width="250" alt="Dashboard">
  <img src="screenshots/cellar.png" width="250" alt="Cellar">
  <img src="screenshots/wine-list.png" width="250" alt="Wine list">
</p>

## Features

- **AI scan** — photograph a label, get structured wine data + price estimate (Claude Sonnet 4.6 vision + Gemini 2.0 Flash web search)
- **Cellar grid** — physical position tracking by row and column
- **Journal** — entry/exit history with tasting notes and ratings
- **Dashboard** — cellar stats, total value, ready-to-drink alerts, recent activity
- **Wine catalog** — full metadata, grape varieties, appellations, drink windows

<p align="center">
  <img src="screenshots/wine-detail.png" width="250" alt="Wine detail">
  <img src="screenshots/journal.png" width="250" alt="Journal">
</p>

<p align="center">
  <img src="screenshots/scan.png" width="250" alt="Scanner">
  <img src="screenshots/scan-review.png" width="250" alt="AI scan review">
</p>

## Tech Stack

| Layer    | Stack                                                                     |
| -------- | ------------------------------------------------------------------------- |
| iOS      | SwiftUI, Swift 6, iOS 26, Apollo iOS, Firebase Auth (Sign in with Apple) |
| Backend  | Nitro on Firebase Cloud Functions Gen 2, Apollo Server 5, Pothos          |
| Storage  | Firestore (multi-user, isolated by `userId`)                              |
| AI       | Claude Sonnet 4.6 (vision), Gemini 2.0 Flash (web search)                 |

## Getting Started

### Backend

```bash
cp .env.example .env  # then fill in your API keys
bun install
bunx nitro prepare
bun run dev           # local Nitro dev server (no Firebase)

# Or run against the Firebase emulator suite:
firebase emulators:start --only auth,firestore,functions
```

Required environment variables (`.env`):

```
NITRO_ANTHROPIC_API_KEY=sk-ant-...
NITRO_GOOGLE_API_KEY=...
NITRO_ADMIN_TOKEN=...   # used by the GitHub Actions post-deploy migrate step
NITRO_SENTRY_DSN=...    # optional
```

### Deploying to Firebase

1. Create a Firebase project and update `.firebaserc` (`projects.default`).
2. Download `GoogleService-Info.plist` (iOS) and place it under `ios/CaveAVin/`.
3. Push to `main` — the GitHub Actions workflow builds, deploys to Cloud
   Functions, applies Firestore rules / indexes, then runs migrations via
   `POST /admin/migrate`.

### iOS App

1. Open `ios/CaveAVin.xcodeproj` in Xcode.
2. Make sure `GoogleService-Info.plist` (gitignored) is added to the bundle.
3. Run `apollo-ios-cli generate` (requires `apollo-ios-cli` installed) to
   regenerate the typed GraphQL operations from `shared/schema.graphql`.
4. Build and run on the iPhone 17 simulator (iOS 26.2).
