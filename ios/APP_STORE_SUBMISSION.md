# App Store submission — Vinarium (unlisted distribution)

Goal: publish Vinarium on the App Store as an **unlisted** app — reachable only via a
direct link, no expiry, no public discoverability. Steps marked **[ASC]** happen in
App Store Connect (need your login); the rest is prepared in this repo.

Facts: bundle `com.polyforms.vinarium.app`, team `46C337T7YN`, version `1.0` build `1`,
automatic signing, deployment target iOS 26.0, backend already deployed.

## Prepared in the repo (done)

- **Privacy policy** — `index.html` on the dedicated **`gh-pages`** branch (the `docs/`
  folder is gitignored on `main`), served at **https://moifort.github.io/vinarium/** (paste
  this as the Privacy Policy URL). To edit: `git checkout gh-pages`, change `index.html`,
  `git push`; GitHub Pages redeploys automatically.
- **Encryption declaration** — `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the app
  target (uses only standard HTTPS), so App Store Connect won't ask about export compliance
  on every upload.
- **`ExportOptions.plist`** — App Store distribution options for the archive export.

## Phase 0 — Prerequisites [ASC]

- App Store Connect → **Business** (Agreements, Tax, Banking): the **Paid/Free Apps**
  agreement must be **active**, otherwise you cannot submit.

## Phase 1 — Create the app record [ASC]

- Apps → **＋ New App** → iOS, bundle `com.polyforms.vinarium.app`, name **Vinarium**,
  primary language **French**, SKU e.g. `vinarium-001`.

## Phase 2 — Metadata & privacy [ASC]

- **Description / keywords / support URL** (your GitHub repo URL is fine).
- **Privacy Policy URL**: `https://moifort.github.io/vinarium/`.
- **App Privacy** questionnaire — answers to select:
  - Data collected & **linked to the user**:
    - *Contact info* → Name, Email (only if the user shares them via Sign in with Apple) — purpose **App Functionality**.
    - *User Content* → the wine catalog, tasting notes, photos of labels — purpose **App Functionality**.
    - *Identifiers* → the Apple user ID / account id — purpose **App Functionality**.
    - *Location* → Coarse/precise location, **only** the discovery place the user opts to save — purpose **App Functionality**.
  - **Not** used for tracking. **No** third-party advertising. **No** data used for tracking across apps.
- **Age rating**: no objectionable content → 4+ (answer "No" to everything; alcohol is *reference to*, set the alcohol/tobacco question to "Infrequent/Mild" if it appears → typically 17+ because the app is about alcohol; answer honestly).
- **Content rights**: you own or are licensed for all content → Yes.

## Phase 3 — Archive & upload [Xcode]

```bash
# 1. Archive (Release, real device destination)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project ios/Vinarium.xcodeproj -scheme Vinarium \
  -destination 'generic/platform=iOS' \
  -archivePath build/Vinarium.xcarchive archive

# 2. Export a signed .ipa using ExportOptions.plist
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -exportArchive \
  -archivePath build/Vinarium.xcarchive \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath build/export
```

Then upload `build/export/Vinarium.ipa` with the **Transporter** app (drag & drop) or via
**Xcode → Organizer → Distribute App**. The build appears in App Store Connect after a few
minutes; attach it to the 1.0 version.

(Easiest alternative: skip the CLI and do Xcode → Product → Archive → Organizer → Distribute App.)

## Phase 4 — Submit for review [ASC]

- **App Review Information → Notes**: "The app requires Sign in with Apple; reviewers can
  sign in with their own Apple ID and an account is created automatically. No demo account
  needed. The backend runs in production." (No demo login required.)
- Screenshots: at least the 6.9"/6.7" iPhone size. Capture from the iPhone 17 simulator once
  signed in (Cmd+S in the simulator saves a correctly-sized PNG).
- **Submit for Review**. Optionally set manual release to keep control.

## Phase 5 — Make it unlisted [ASC + form]

- Once the app is **approved** (you can hold the public release), request unlisted
  distribution: **https://developer.apple.com/contact/request/unlisted-app-distribution**
  (some accounts also expose an unlisted option in App Store Connect at publish time).
- Apple grants a direct `apps.apple.com/...` link that is hidden from search, charts and
  browsing. Share it with whoever should get the app — no device limit, no expiry, automatic
  updates.

## Updates later

Bump `CURRENT_PROJECT_VERSION` (build number), re-archive (Phase 3), submit (Phase 4).
Installed users update automatically like any App Store app.
