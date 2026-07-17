# Freemium / Paid Model + On-Device Scan — Feasibility & Macro Plan

> Status: **decision document** (feasibility + macro). No implementation yet.
> Economics (Q4) revised 2026.07.17: VAT-corrected proceeds, no-deficit quota structure,
> dev-funding milestones.

## Context

Vinarium wants a **freemium** model. Goal: offset the AI scan cost (today fully borne by the app)
by reserving the Google AI scan for paying subscribers, while offering free users an **on-device**
scan (Apple Intelligence / Vision) at zero server cost, plus limits (AI trial, bottle cap). This
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
| B | **Cloud AI trial** | 5 full Gemini scans **once** (lifetime), then on-device / vision-only | Unlimited vision scans; enrichment hard-capped (fair use, see Q4) | Lets users taste cloud quality. Lifetime, not monthly: a monthly grounded quota is a structural deficit once grounding is billed (Q4). |
| C | **Bottle cap** | Cap on the **library** (`beverages`), e.g. 25–50 | Unlimited | Capping the library is enough: the cellar is included (see ⚠️). Needs a new `.count()` aggregate. |
| D | **Market enrichment** | ❌ (only name/vintage/type via OCR) | ✅ estimated price, grapes, appellation, drinking window | Elegant: isolates *exactly* the cost (grounding). Free still gets a useful scan. |
| E | **Shared household** | Solo | Shared family cellar (`household`) | Household infra already present; simple gate. |
| F | **Advanced stats / dashboard, export** | Basic | Full (cellar value, tasting history, CSV/PDF export) | Zero server cost, high perceived value. |

**Recommendation**: combine **A + B + C + D** as the backbone, keep **E/F** in reserve to enrich the
paid tier at no extra cost. The **B (lifetime trial) + D (paid enrichment)** pair is the most
profitable because it targets the real cost source rather than blocking everything.

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
  free user hits a limit (trial exhausted, bottle cap) or from settings.
- **Scan routing**: `ScannerFactory` (Q2) reads `EntitlementStore.tier`.

**Increments**: (B1) `entitlement` domain + collection + claim → (B2) iOS StoreKit 2 +
`EntitlementStore` + server validation → (B3) scan gating (quota + `scan-usage`) → (B4) bottle-cap
gating (`beverages.count` aggregate) → (B5) paywall UI.

---

## Q4 — Economics: no-deficit model & dev-funding milestones

> Revised 2026.07.17. Priorities set with the owner: **phase 1 = cover AI + infra (no deficit)**;
> funding future devs is a phase-2 milestone, quantified below. Target audience: **< 1,000 MAU**
> at 12–18 months. USD→EUR conversions use ≈ 1.10 throughout.

### Net revenue per subscriber (the previous estimate was ~20% too high)

Apple computes its commission on the price **excluding VAT** (20% in France), not on the sticker
price. With the Small Business Program (15% — enrollment is not automatic, see Risks):

| Sticker price | Net proceeds / month | Previous estimate (wrong) |
|---|---|---|
| €4.99/month | **€3.53** | €4.24 |
| €34.99/year | **€2.07** | €2.48 |
| €39.99/year (new recommendation) | **€2.36** | — |

€34.99/year was the weak spot (€2.07 net/month). **Keep monthly at €4.99, move annual to €39.99**
(still well under Vivino ≈ €50/year). Price is not the deficit risk (see below); raising the
monthly price is a phase-2 lever only.

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

### Costs at the target scale (< 1,000 MAU): AI is nearly free

- Even the absolute worst case (1,000 MAU all scanning 30×/month **on the cloud path**) stays
  under the free grounding tier (~1,000 scans/day) and costs 30,000 × $0.003 ≈ **$90/month**
  (tokens only). The realistic bill is far lower: with the recommended structure only subscribers
  and lifetime trials hit Gemini (~30–50 subs × 30 scans ≈ 1,500 scans/month) → **< $10/month**.
  Weekend bursts past 1,500 grounded req/day are marginal.
- Fixed costs: Apple Developer ~€8/mo, domain ~€2/mo, GCP (Cloud Run scales to zero, Firestore
  read-optimized) ~€5–15/mo, Sentry free tier → **floor ≈ €15–30/month**. (Hygiene: lower Sentry
  `tracesSampleRate: 1.0` before any growth — 100% transaction tracing is a per-event billing
  driver.)

**Phase-1 break-even: ~6–12 subscribers** (€15–30 fixed floor at ~€2.50/month blended net
margin). Very reachable.

### The real deficit risk: a monthly free quota with grounding

An earlier draft gave free users 5–10 **full** Gemini scans (with grounding) per month. Free while
the grounding free tier holds — but once grounding is billed (growth, or a forced migration when
2.5 is deprecated): 10 scans × $0.037 = $0.37 per free user per month. At 3% conversion each
subscriber "carries" ~33 free users → **~€11/month of cost against €3.53 of net revenue: a 3×
structural deficit.** Structural fixes (no deficit by construction, at any volume):

- **Free quota = one-time lifetime trial** (5 full scans), not monthly. Afterwards: **on-device**
  (lever A — Apple Intelligence, else Vision OCR: zero server cost, no unbounded free-tier
  spend); market enrichment stays the paid differentiator (lever D unchanged). A cloud
  vision-only fallback (~$0.0016/scan) would work too, but it reintroduces an uncapped
  per-free-user cost — prefer on-device.
- **Paid tier: hard cap on enrichment, not on scans** — ~60 enrichments/month; vision scans stay
  unlimited for subscribers (negligible cost). Worst billed case: 60 × $0.035 ≈ €1.90, under the
  lowest recommended net (€2.36, the €39.99 annual) → no subscriber can ever be unprofitable.
  Replaces the earlier 300-scan soft cap (300 × $0.035 ≈ €10: a guaranteed loss on abusers).

Gemini 3.x sensitivity: grounding moves to $14/1,000 queries with 5,000/month free → ~$0.014 per
enriched scan, **cheaper** than billed 2.5. A future migration does not worsen the model.

### Phase 2 — dev-funding milestones (honest numbers)

Blended net margin ≈ €2.50/subscriber/month (40% monthly / 60% annual at €39.99, AI and infra
deducted). At < 1,000 MAU with 3–5% conversion: 30–50 subscribers → **~€75–130/month**. That
covers costs and validates willingness to pay; **it pays no dev.** The milestones:

| Dev budget | Subscribers needed | MAU needed (3–5% conv.) |
|---|---|---|
| Freelance ~€2,000/mo | ~800 | ~16,000–27,000 |
| 1 full-time dev ~€6,000/mo | ~2,400 | ~48,000–80,000 |

These tiers are the phase-2 growth targets; the price lever (monthly €5.99–6.99) cuts the required
subscribers by ~30% and will be reassessed with real `scan-usage` data. Sensitivity: at those
scales grounding is billed, so a subscriber using ~15 enrichments/month costs ~€0.50; if the real
blended margin lands at €2.00 instead of €2.50, the milestones become ~1,000 and ~3,000
subscribers.

**Market benchmarks**: Vivino Premium ≈ €50/year, competing cellar apps €3–5/month → **€4.99/month
/ €39.99/year** stays consistent with the market.

**Recommendation**: launch at **€4.99/month** and **€39.99/year**; free tier = **5 full scans
lifetime** then vision-only / on-device, free cap **~30 bottles** (library); paid tier = unlimited
vision scans + **60 enrichments/month** hard cap. Adjust after observing real costs (the
`scan-usage` counter provides the data).

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
- **Small Business Program**: the 15% rate requires **explicit enrollment** in App Store Connect
  (it is not automatic); without it, subscriptions pay 30% their first year and every net figure
  in Q4 drops accordingly. Enroll before launch.
- **Gemini 2.5 deprecation**: the cost model survives a forced migration to 3.x (grounding
  $14/1,000 queries, 5,000/month free → ~$0.014 per enriched scan, cheaper than billed 2.5), but
  re-run the Q4 numbers at migration time.
- **Sentry tracing**: `tracesSampleRate: 1.0` (100% of transactions) is fine today but becomes a
  billing driver with traffic; lower it before any growth push.
- **On-device quality**: free without web enrichment has no price or drinking window; present it as
  a differentiator, not a bug.
- **Migration**: introducing `entitlements`/`scan-usage` = new collections → **no Firestore
  migration required** (adding collections, per CLAUDE.md). The custom claim does not affect
  existing users (default = `free`).
- **Cellar/collection overlap**: cap the **library** (`beverages`) only; never sum cellar +
  collection (double counting).
