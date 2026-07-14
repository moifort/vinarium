# Freemium / Paid Model + On-Device Scan — Feasibility & Macro Plan

> Status: **decision document** (feasibility + macro). No implementation yet.

## Context

Vinarium wants a **freemium** model. Goal: offset the AI scan cost (today fully borne by the app)
by reserving the Google AI scan for paying subscribers, while offering free users an **on-device**
scan (Apple Intelligence / Vision) at zero server cost, plus limits (AI quota, bottle cap). This
document answers four questions: freemium ideas, on-device scan feasibility, subscription
feasibility, and a price estimate that yields a margin.

### Current state (verified in the code)

- **Scan today** — `server/domain/scan/index.ts` calls **Gemini 2.5 Flash** in **2 requests** per
  scan: (1) vision (base64 image → structured `ScanResult` JSON), (2) enrichment with the
  `google_search` tool (market price, grape varieties, appellation, drinking window). Image capped
  client-side at 800 px / JPEG q0.6. Firestore `scan-cache` keyed by SHA-256 (rarely hits, since
  lossy recompression changes the hash). **No token counting, no quota, no caller identity** in the
  scan domain.
- **iOS** — `ios/Vinarium/Features/Scan/`. `ScanViewModel.capturePhoto(_:)` hard-calls
  `WineAPI.scan(imageData:)` (`WineAPI.swift:96`). Target **iOS 26 / Swift 6**, **Sign in with
  Apple** only. **No** on-device frameworks (Vision / FoundationModels), **no** StoreKit /
  RevenueCat.
- **User** — no user document. Identity = Firebase UID, exposed as `event.context.userId`
  (`server/middleware/auth.ts:26`). The only stored "profile" is household membership
  (`household-members`).
- **Bottles** — two collections. "Collection / library" = `beverages` (personal superset).
  "Cellar" (cave) = `cellar` (subset physically placed in the 6×8 grid, 48 slots). ⚠️ **The cellar
  is a subset of the library** (a placed bottle = 1 `beverages` doc + 1 `cellar` doc). `cellar`
  already has a `.count()` aggregate (`cellar/infrastructure/repository.ts:49`); `beverages` does
  **not** (only `findAllByUser`, which scans everything).

### Product decisions already made

1. Fallback for devices **without Apple Intelligence** (iPhone 14 and earlier, 15/15 Plus non-Pro):
   **Vision OCR only** + local heuristic structuring (universal, zero server cost).
2. Entitlement: **StoreKit 2 + server claim** (receipt validation on Nitro, entitlement in a new
   Firestore user doc + Firebase custom claim).

---

## Q1 — Freemium ideas

**Core cost insight**: on a scan, **~95% of the cost is the `google_search` grounding**
(~$0.035 beyond the free tier), not tokens or Firestore. So the best lever is not just "who gets
AI" but **which AI steps are paid**. That enables a finer split than "all AI = paid".

| # | Lever | Free | Paid | Note |
|---|-------|------|------|------|
| A | **Scan** (original idea) | On-device: Apple Intelligence if available, else Vision OCR | Gemini vision + web enrichment | Core of the proposal. |
| B | **Cloud AI quota** | N free Gemini scans / month, then on-device | Unlimited | Lets users taste cloud quality. `N ≈ 5–10`. |
| C | **Bottle cap** | Cap on the **library** (`beverages`), e.g. 25–50 | Unlimited | Capping the library is enough: the cellar is included (see ⚠️). Needs a new `.count()` aggregate. |
| D | **Market enrichment** | ❌ (only name/vintage/type via OCR) | ✅ estimated price, grapes, appellation, drinking window | Elegant: isolates *exactly* the cost (grounding). Free still gets a useful scan. |
| E | **Shared household** | Solo | Shared family cellar (`household`) | Household infra already present; simple gate. |
| F | **Advanced stats / dashboard, export** | Basic | Full (cellar value, tasting history, CSV/PDF export) | Zero server cost, high perceived value. |

**Recommendation**: combine **A + B + C + D** as the backbone, keep **E/F** in reserve to enrich the
paid tier at no extra cost. The **B (quota) + D (paid enrichment)** pair is the most profitable
because it targets the real cost source rather than blocking everything.

---

## Q2 — On-device iOS scan: feasibility & macro plan

**Feasibility: high.** Everything is provided by iOS 26; the target is already `26.0`.

On-device pipeline (0 server calls, produces the **same `ScanResult`** as the cloud path):

1. **OCR** — **Vision** framework (`RecognizeTextRequest`, iOS 26 async API) on the `UIImage`
   already captured by `CameraView` / `PhotosPicker`. Available on **all** iOS 26 devices.
2. **Structuring** — two branches by hardware:
   - **Apple Intelligence available** (iPhone 15 Pro+, A17 Pro/A18+): `FoundationModels`
     (`SystemLanguageModel` / `LanguageModelSession`) with a `@Generable` type mirroring
     `ScanResult` → direct structured extraction (name, domain, vintage, appellation, grapes…).
   - **Otherwise** (decision: *Vision OCR only*): local heuristic parsing of the OCR text (vintage
     regex `19|20xx`, ABV `%`, appellation/grape dictionaries) → partial `ScanResult`, lower
     quality but usable, editable in `ScanReviewPage`.
3. **Runtime detection**: `SystemLanguageModel.default.availability` picks the branch. Routing
   combines **two** conditions: entitlement (Q3) **and** hardware capability.

**Macro plan (iOS)**:

- **`WineScanner` abstraction** (protocol) with 3 implementations: `ServerScanner` (current
  `WineAPI.scan`), `OnDeviceIntelligenceScanner` (Vision + FoundationModels), `OnDeviceOCRScanner`
  (Vision + heuristic). A `ScannerFactory` picks based on `entitlement × availability`.
- **Single insertion point**: `ScanViewModel.capturePhoto(_:)` (`ScanViewModel.swift:41-54`) —
  replace the hard `WineAPI.scan` call with `scanner.scan(imageData:)`. **The rest of the flow is
  unchanged** (`.review(ScanResult, Data)` → `WineAPI.create`), since all 3 paths return a
  `ScanResult`.
- **What is NOT on-device**: wine creation (`WineAPI.create`), tasting, recommendations stay
  server-side. Only *extraction* moves on-device.
- **Quality limit to accept**: market enrichment (price, drinking window) comes from the web
  (grounding) — **impossible on-device**. This is precisely what becomes the paid differentiator
  (idea D). Free on-device will not fill `estimatedPrice`/`drinkFrom`/`drinkUntil`.

**Increments**: (L1) `WineScanner` + `ServerScanner` (behavior-preserving refactor) → (L2)
`OnDeviceOCRScanner` (Vision, universal) → (L3) `OnDeviceIntelligenceScanner` (FoundationModels) →
(L4) entitlement-based routing (depends on Q3).

---

## Q3 — Free / paid subscription: feasibility & macro plan

**Feasibility: medium** — payment is greenfield, but the auth anchor already exists
(`event.context.userId` on every request). Chosen mechanism: **StoreKit 2 + server validation +
custom claim**.

**Macro plan (backend, Nitro/DDD)**:

- **New `server/domain/entitlement/` domain** (follow `docs/domain-guide.md` + the `ddd-architecture`
  skill): `types.ts` (`Entitlement { userId, tier: 'free'|'pro', source, expiresAt, ... }`),
  `command.ts` (`EntitlementCommand.activateFromReceipt`, `.refreshFromNotification`), `query.ts`
  (`EntitlementQuery.currentTier`), `infrastructure/repository.ts` (new Firestore `entitlements`
  collection, doc id = `userId` → **the project's first per-user document**).
- **Receipt validation**: an endpoint that receives the StoreKit 2 `JWSTransaction`, verifies it
  against the **App Store Server API** (Apple keys), writes the entitlement, and **sets a Firebase
  custom claim** (`tier: 'pro'`) via `admin.auth().setCustomUserClaims` → the claim then travels for
  free in the ID token (already injected by `FirebaseTokenInterceptor`), readable server-side **and**
  on iOS with no Firestore read.
- **App Store Server Notifications V2**: webhook (admin-like route) for renewals / cancellations /
  refunds → keeps the entitlement current outside the app.
- **Server-side quota enforcement** (the reason for the server claim):
  - The `scan` domain must become **caller-aware**: read `userId` in the `scanBeverage` mutation,
    reject (or decrement) based on tier. New domain outcome e.g. `QUOTA_EXCEEDED` mapped to
    `badUserInput` (see `docs/error-handling.md`).
  - **AI usage counter**: a lightweight collection (`scan-usage`, doc `${userId}_${YYYYMM}`)
    incremented on each Gemini scan; compared to the tier quota.
  - **Bottle cap**: add a `beverages().where('userId','==',userId).count()` aggregate (mirror of
    `cellar.countByUser`) — do **not** use `findAllByUser` (full scan). Gate at the `beverage`
    domain's `create` mutation.

**Macro plan (iOS)**:

- **StoreKit 2**: `Product.products(for:)`, `product.purchase()`, `Transaction.currentEntitlements`,
  `Transaction.updates` (listen to renewals). A `.storekit` config file for simulator testing.
- **`EntitlementStore`** (`@Observable`, app scope next to `AuthSession`): reads the tier from
  (a) the ID token custom claim AND (b) local StoreKit; exposes `tier` to the rest of the app.
- **Paywall**: new `Features/Paywall/` feature (coordinator + previewable `*Page`), shown when a
  free user hits a limit (AI quota, bottle cap) or from settings.
- **Scan routing**: `ScannerFactory` (Q2) reads `EntitlementStore.tier`.

**Increments**: (B1) `entitlement` domain + collection + claim → (B2) iOS StoreKit 2 +
`EntitlementStore` + server validation → (B3) scan gating (quota + `scan-usage`) → (B4) bottle-cap
gating (`beverages.count` aggregate) → (B5) paywall UI.

---

## Q4 — Price estimate for a margin

### Real cost per scan (cache miss, Gemini path)

Verified rates (July 2026): Gemini 2.5 Flash **$0.30/M in**, **$2.50/M out**; Google Search
grounding **1,500 req/day free** then **$35/1,000** (= $0.035/req) for 2.x models.

| Item | Small scale (<1,500 scans/day) | At scale (grounding billed) |
|---|---|---|
| Vision (~2k in tok + ~0.4k out tok) | ~$0.0016 | ~$0.0016 |
| Enrichment (tokens) | ~$0.001 | ~$0.001 |
| `google_search` grounding | **$0** (free tier) | **$0.035** |
| **Total / scan** | **~$0.003** | **~$0.037** |

**Firestore / Cloud Run per user/month**: read-optimized architecture (loaders, aggregates) →
**< $0.02/user/month**, negligible vs AI. Storage: negligible (no images stored).

### Monthly cost of a paying subscriber (unlimited cloud scans)

| Profile | Scans/month | AI cost at scale |
|---|---|---|
| Occasional | 10 | ~$0.37 |
| Regular | 30 | ~$1.11 |
| Heavy | 100 | ~$3.70 |

Free (on-device) costs **~$0** server-side — the whole point of the model.

### Recommended price

- **Monthly: €4.99** — **Annual: €34.99** (≈ 2 months free, nudges toward annual).
- Apple commission **15%** (Small Business Program, < $1M/year) → net ≈ **€4.24/month** or
  **€29.74/year**.
- **Margin**: even a *heavy* subscriber (100 scans, ~$3.70 ≈ €3.4) stays profitable monthly; the
  median subscriber (10–30 scans) leaves **> €3/month**. Abuse risk (hundreds of scans) is covered
  by (a) scanning one's cellar being a one-off act, (b) an optional documented fair-use soft cap
  (e.g. 300 scans/month).

**Market benchmarks**: Vivino Premium ≈ €50/year, competing cellar apps €3–5/month → **€4.99/month
/ €34.99/year** is consistent and leaves a healthy margin.

**Recommendation**: launch at **€4.99/month** and **€34.99/year**, free quota **5–10 Gemini
scans/month** then on-device, free cap **~30 bottles** (library). Adjust after observing real costs
(the `scan-usage` counter provides the data).

---

## Verification (how to validate the future build)

- **Real AI cost**: instrument `usageMetadata` (currently ignored, `scan/index.ts:153`) + the
  `scan-usage` collection to measure real tokens/grounding and **recalibrate the price**.
- **On-device scan**: test `OnDeviceOCRScanner` in the simulator (iPhone 17, iOS 26.2 — Vision OK)
  and `OnDeviceIntelligenceScanner` on a real Apple Intelligence device; verify all 3 scanners
  produce a valid `ScanResult` consumed by `ScanReviewPage`.
- **Subscription**: a `.storekit` file in the simulator for the purchase; verify the `tier:'pro'`
  custom claim reaches the ID token and unlocks scan routing + lifts the gates.
- **Gates**: `*.int.test.ts` tests on the quota (`QUOTA_EXCEEDED`) and the bottle cap, asserting
  read budgets (`fake.docReads`/`fake.queryReads`) — the `beverages.count` aggregate must cost
  **1 queryRead**, never a full scan.

## Risks & open points

- **App Store Review**: Apple requires paid features to go through IAP (no external payment). The
  "cloud AI = paid" model is compliant.
- **On-device quality**: free without web enrichment has no price or drinking window; present it as
  a differentiator, not a bug.
- **Migration**: introducing `entitlements`/`scan-usage` = new collections → **no Firestore
  migration required** (adding collections, per CLAUDE.md). The custom claim does not affect
  existing users (default = `free`).
- **Cellar/collection overlap**: cap the **library** (`beverages`) only; never sum cellar +
  collection (double counting).
