# Freemium / Paid Model + On-Device Scan — Feasibility & Macro Plan

> Status: **partly superseded, 2026.07.21**. The economics (Q4) are replaced by
> [freemium-economics.md](./freemium-economics.md), which corrects the cost of a scan (thinking
> tokens were not counted) and settles on a monthly scan quota rather than a lifetime trial plus
> a bottle cap. The entitlement mechanism shipped is the one proven in the sibling project: a
> Firestore entitlement read per request and an `appAccountToken` derived from the user id, not
> the Firebase custom claim described in Q3. **Q2 (on-device scanning) is still the reference**
> for that postponed release, and the Q1 lever table still reads true.

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

> **Postponed.** Release 1 ships without any on-device scanning; the free tier stays on the
> capped cloud vision-only scan (see Q4 and the implementation plan). This section is kept as
> the reference for a possible later release.

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
gating (`beverages.count` aggregate) → (B5) paywall UI. Superseded by the detailed sequencing in
the implementation plan section (its increment numbering differs).

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

---

## Implementation plan — release 1 (monetization only)

> Scoped 2026.07.17. On-device scanning (Q2) is postponed: after the lifetime trial, free users
> get the capped cloud vision-only scan. Old installed builds don't know the paywall, so
> enforcement is **temporarily tolerant**: the server only enforces quotas for builds that send
> an `X-App-Build` header at or above the paywall release's build number. The grace period ends
> later with a one-line `MINIMUM_SUPPORTED_IOS_BUILD` bump.

### Key architectural decisions (they shape everything)

1. **`scanBeverage` must NOT change its return type.** Turning it into a union would break
   already-installed clients whose query is `scanBeverage { name ... }` (invalid against a union
   without inline fragments). The whole old-client grace design depends on the schema staying
   backward-compatible. Therefore quota outcomes are signalled with a **coded GraphQL error**
   (`extensions.code = QUOTA_EXCEEDED`, `reason: 'trial_exhausted' | 'monthly_cap'`), not a
   union. Same for the bottle cap (`BOTTLE_CAP_EXCEEDED`). This matches the existing
   `POSITION_OCCUPIED` / `IMAGE_TOO_LARGE` precedent (`domainError`). New clients read
   `extensions.code`; old clients never enforce (no header) so never see the code. Server error
   messages stay English; iOS renders the French copy keyed on the code.
2. **Tier resolution is custom-claim-first on the hot path.** `event.context.tier` is derived
   from the already-verified ID token (`decoded.tier`), so scan gating costs **zero reads** for
   tier. `EntitlementQuery.currentTier(userId)` (a Firestore read that recomputes
   `tier = expiresAt > now`) exists only for token-less contexts (the webhook). The webhook
   re-writes the claim on every state change, so the claim is at most ~1h stale (Firebase
   auto-refresh) — fine for a monthly cap and generous for expiry.
3. **Cache hits never touch quotas.** The Gemini call is the only cost; a `scan-cache` hit is
   free and rare (lossy recompression changes the SHA-256). Gating decides only whether the
   *enrichment* Gemini call is made on a cache **miss**. Cache hits return as-is (a harmless
   upside for free users), and increments happen only when a real vision call occurs. Trial is
   also not decremented on cache hits.
4. **Every increment is deploy-dark until the header arrives.** All backend enforcement sits
   behind `shouldEnforceQuota(appBuild)`, false when `X-App-Build` is absent or below threshold.
   So every backend increment below is safe to push to `main` (auto-deploy) before any iOS
   release exists.

### B0 — Header + tier plumbing (dark, no enforcement)

Goal: carry `appBuild` and `tier` into request and GraphQL context. No behavior change.

**Modify**
- `server/middleware/auth.ts`: after `verifyIdToken`, set
  `event.context.tier = decoded.tier === 'pro' ? 'pro' : 'free'` and
  `event.context.appBuild = Number(getHeader(event, 'x-app-build')) || undefined`. Extend the
  `declare module 'h3'` block with `tier?: 'free' | 'pro'` and `appBuild?: number`.
- `server/routes/graphql.ts`: pass `tier: event.context.tier ?? 'free'` and
  `appBuild: event.context.appBuild` into the context factory.
- `server/domain/shared/graphql/builder.ts`: add `tier: 'free' | 'pro'` and `appBuild?: number`
  to `GraphQLContext`.
- `server/system/app-support.ts`: add `export const QUOTA_ENFORCEMENT_MIN_BUILD = <threshold>`
  next to `MINIMUM_SUPPORTED_IOS_BUILD`, with a comment that it is the build number of the first
  paywall-carrying iOS release.

**Create**
- `server/domain/entitlement/enforcement.ts`:
  `export const shouldEnforceQuota = (appBuild?: number) => appBuild != null && appBuild >= QUOTA_ENFORCEMENT_MIN_BUILD`.

**Tests**: `enforcement` unit test (below/at/above threshold, undefined). Existing feat-test
`execute` closures gain `tier`/`appBuild` in `contextValue` (default `'free'`, undefined).

### B1 — `entitlement` domain + custom claim (dark)

Firestore doc **`entitlements/{userId}`** (first per-user doc; id = userId):

```
{
  userId: UserId
  tier: 'free' | 'pro'
  source: 'app_store'
  productId: string                 // 'com.polyforms.vinarium.pro.monthly' | '.yearly'
  originalTransactionId: string
  expiresAt: Date | null            // subscription paid-through date
  autoRenew: boolean
  environment: 'Production' | 'Sandbox'
  updatedAt: Date
}
```

Absence of the doc ⇒ free.

**Create** (mirror `server/domain/gift/`)
- `types.ts`: `Tier = 'free' | 'pro'`, `Entitlement` (shape above), `AppStoreEnvironment`.
- `primitives.ts`: `ProductId` brand + `TIER_BY_PRODUCT` map;
  `deriveTier(expiresAt): Tier = expiresAt && expiresAt > new Date() ? 'pro' : 'free'`.
- `infrastructure/repository.ts`: `entitlements()` via `genericDataConverter<Entitlement>()`;
  `findBy(userId)` (memoizedPerRequest), `save(entitlement)` (doc id = userId).
- `query.ts`: `EntitlementQuery.currentTier(userId) = deriveTier((await repository.findBy(userId))?.expiresAt ?? null)`.
- `command.ts`: `EntitlementCommand.apply(userId, decoded)` builds the `Entitlement`,
  `repository.save`, then `syncClaim(userId, tier)`; `syncClaim` =
  `getAuth().setCustomUserClaims(uid, tier === 'pro' ? { tier: 'pro' } : {})` (clear the claim
  when free, so the token stops carrying `tier`). Keep it the single writer of the claim.
- To mock `getAuth`, add a thin wrapper `server/system/firebase-auth.ts` (`setUserTier`) so tests
  `mock.module` it, mirroring the `~/system/firebase` pattern.

**Tests**: `command.int.test.ts` — `apply` writes the doc with correct `tier`/`expiresAt` and
(mock `setUserTier`) calls it with `{ tier: 'pro' }` when active, `{}` when expired.
`query.int.test.ts` — boundary at `expiresAt`, missing doc ⇒ free (1 docRead, memoized).

### B2 — Apple verification: client submit + webhook (dark)

**Library: `@apple/app-store-server-library`** (official). It bundles Apple's root-CA chain
verification (`SignedDataVerifier`) — manually verifying the JWS `x5c` chain up to **Apple Root
CA G3** with `jose` is the single biggest correctness pitfall (skipping it = forgeable
transactions). It also gives the App Store Server API client (for reconciliation) using the
In-App-Purchase `.p8`. It is a runtime dependency (not a peer), so it won't conflict with the
`graphql <17` / `firebase-admin <14` peer pins; after adding, run `npm ls jsonwebtoken` to
confirm no incompatible transitive. **Fallback**: `jose` + a vendored `AppleRootCA-G3.cer` with
manual chain verification. **Vendor** `AppleRootCA-G3.cer` into
`server/domain/entitlement/infrastructure/apple/` and pass it to `SignedDataVerifier`.

**Environments**: build two verifiers (Production, Sandbox) with `bundleId` + `appAppleId`; try
Production, retry Sandbox on an environment-mismatch decode error. Persist `environment` on the
entitlement so the webhook picks the right verifier.

**Client submit — GraphQL mutation** (recommended over REST: the client already speaks GraphQL
with the bearer token, so auth/user-context is free and it returns the typed tier the UI needs):

```graphql
enum Tier { free pro }
type EntitlementStatus { tier: Tier!  expiresAt: DateTime }
extend type Mutation {
  """Verify a StoreKit 2 signed transaction and (re)compute the user's entitlement."""
  submitAppStoreTransaction(signedTransactionInfo: String!): EntitlementStatus!
}
```

**Create**
- `infrastructure/apple/verifier.ts`: wraps `SignedDataVerifier`; `verifyTransaction(jws)` and
  `verifyNotification(signedPayload)` returning a normalized `DecodedTransaction
  { originalTransactionId, productId, expiresAt, environment, autoRenew }`. Reads key material
  from `config()`.
- `infrastructure/graphql/{enums.ts (Tier), types.ts (EntitlementStatusType), mutations.ts}` —
  `submitAppStoreTransaction` → `verifier.verifyTransaction` → `EntitlementCommand.apply` →
  return status. Register the new block in `server/domain/shared/graphql/schema.ts`.

**Webhook — App Store Server Notifications V2** (`server/routes/webhooks/app-store.post.ts`)
- **Auth whitelist**: add a branch in `auth.ts` — `if (path.startsWith('/webhooks/app-store')) return`
  (Apple signs with JWS, not a Firebase token; security = `verifyNotification`, not bearer).
- Body `{ signedPayload }` → `verifier.verifyNotification` →
  `{ notificationType, subtype, data.signedTransactionInfo, data.signedRenewalInfo }`.
- **Idempotency**: `app-store-notifications/{notificationUUID}` set-if-absent; skip if seen.
  Application is also naturally idempotent (recompute `expiresAt`; latest `signedDate` wins).
- **Events** → all funnel to `EntitlementCommand.apply`:
  `DID_RENEW` / `SUBSCRIBED` / `DID_CHANGE_RENEWAL_STATUS` (updates `autoRenew`) → apply;
  `EXPIRED` / `GRACE_PERIOD_EXPIRED` / `REVOKE` → `expiresAt` past ⇒ tier→free ⇒ claim cleared;
  `REFUND` → tier→free; unknown → 200 no-op (Apple retries otherwise). Return 200 on success.

**Tests**: `mutations.feat.test.ts` — mock `verifier`, assert the mutation writes the entitlement
and returns `{ tier: 'pro' }`. Webhook route test — mocked-verified `EXPIRED` ⇒ tier→free, claim
cleared; duplicate `notificationUUID` ⇒ single application. The verifier itself is
integration-only (not unit-tested against real Apple signatures); wrap it so the domain mocks it.

### B3 — Usage metering + scan gating (dark until header)

**Fake-firestore extension first** (needed for tests): add atomic-increment support. Re-export
`increment(n)` through `server/system/firebase.ts` (so tests can mock); in the fake, teach
`set(doc, {...}, { merge: true })` to apply `existing + by` when a field is the increment
sentinel `{ __op: 'increment', by: n }` rather than overwrite; keep tracking `directWrites`.
~15-line addition to `server/test/fake-firestore.ts`.

**Atomic strategy**: `FieldValue.increment(1)` via `set(doc, {...}, { merge: true })` — one write
per scan, correct under `concurrency: 80`, no transaction round-trip. The gating *read* is
separate and eventually consistent; slight drift on a 60-cap is harmless.

**Doc shapes** (collection `scan-usage`, no migration, default-deny rules unchanged)
- Monthly `scan-usage/{userId}_{YYYYMM}`: `{ userId, period, visionScans, enrichments, updatedAt }`.
- Lifetime trial `scan-usage/{userId}`: `{ userId, trialScansUsed, updatedAt }` — a separate doc
  because the trial is lifetime, must survive month rollover and entitlement webhook overwrites.

**Create**
- `server/domain/scan/infrastructure/usage-repository.ts`: `monthlyUsage(userId)`,
  `trialUsage(userId)` (both memoizedPerRequest, 1 docRead each), `incrementMonthly(userId,
  { vision, enrichment })`, `incrementTrial(userId)`.
- `server/domain/scan/quota.ts`: constants `FREE_TRIAL_SCANS = 5`, `FREE_MONTHLY_VISION_CAP = 30`,
  `PRO_MONTHLY_ENRICHMENT_CAP = 60` + `planFor(tier, trialUsed, monthlyVision, monthlyEnrich):
  'full' | 'vision' | 'blocked'`.
  - pro: `enrich < 60 → 'full'`, else `'vision'` (unlimited vision).
  - free: `trialUsed < 5 → 'full'`; else `monthlyVision < 30 → 'vision'`; else `'blocked'`.

**Refactor** `server/domain/scan/index.ts`: `Scan.scanWithCache(buffer, { enrich })` returns
`{ result, cacheHit, enriched }`. Cache hit → return cached, `cacheHit: true`. Miss → `scanLabel`,
then `enrichWithSearch` only if `enrich && result.recognized`. Capture `usageMetadata`
opportunistically (widen the inline response types) for later cost calibration.

**Rewrite resolver** `server/domain/scan/infrastructure/graphql/mutations.ts`:

```
resolve(_root, { imageBase64 }, { userId, tier, appBuild }) {
  // size check unchanged (IMAGE_TOO_LARGE)
  const enforce = shouldEnforceQuota(appBuild)
  let plan = 'full'
  if (enforce) {
    const trial = await trialUsage(userId)              // 1 docRead
    const monthly = await monthlyUsage(userId)          // 1 docRead
    plan = planFor(tier, trial.trialScansUsed, monthly.visionScans, monthly.enrichments)
    if (plan === 'blocked') return quotaExceeded(reason)   // throws coded error
  }
  const { result, cacheHit, enriched } = await Scan.scanWithCache(buffer, { enrich: plan === 'full' })
  if (enforce && !cacheHit) {                            // real Gemini call → meter
    if (tier === 'free' && plan === 'full') await incrementTrial(userId)
    await incrementMonthly(userId, { vision: true, enrichment: enriched })
  }
  return result
}
```

`server/domain/shared/graphql/errors.ts` gains
`quotaExceeded = (reason: 'trial_exhausted' | 'monthly_cap'): never => { throw new GraphQLError('Quota reached', { extensions: { code: 'QUOTA_EXCEEDED', reason } }) }`.

**Tests** (`mutations.feat.test.ts`, mock `Scan.scanWithCache`): no header ⇒ never blocked, no
usage reads/writes; free trial<5 ⇒ `enrich:true`, `trialScansUsed`++; free trial exhausted,
vision<30 ⇒ `enrich:false`, vision++, no enrichment; free both exhausted ⇒
`extensions.code === 'QUOTA_EXCEEDED'`; pro enrich<60 ⇒ full; pro enrich≥60 ⇒ vision-only,
unlimited; cache hit ⇒ no increment (writes == 0).

### B4 — Bottle cap (dark until header)

Add `countByUser(userId)` to `server/domain/beverage/infrastructure/repository.ts` =
`beverages().where('userId','==',userId).count().get()` (1 queryRead, mirror of
`cellar/infrastructure/repository.ts` `countByUser`); expose via `BeverageQuery.countByUser`.

Gate in the `addBeverage` resolver, before `BeverageUseCase.add` (keep `BeverageCommand.add`
pure — tier is a context concern):

```
if (shouldEnforceQuota(appBuild) && tier === 'free') {
  const count = await BeverageQuery.countByUser(userId)     // 1 queryRead
  if (count >= FREE_BOTTLE_CAP) return domainError('BOTTLE_CAP_EXCEEDED', 'Bottle cap reached for the free tier')
}
```

`FREE_BOTTLE_CAP = 30`. **Tests** (beverage feat test): free at cap ⇒ `BOTTLE_CAP_EXCEEDED`, and
the count costs exactly **1 queryRead** (never a full scan); pro/unenforced ⇒ add succeeds.

### B5 — `me` extension (tier + usage for paywall/settings)

```graphql
type UsageStatus {
  trialScansRemaining: Int!      # max(0, 5 - trialScansUsed); 0 for pro
  enrichmentsUsed: Int!
  enrichmentsCap: Int            # 60 for pro, null (n/a) for free
  bottleCount: Int!
  bottleCap: Int                 # 30 free, null = unlimited (pro)
}
extend type Me {
  tier: Tier!
  usage: UsageStatus!
}
```

`server/domain/user/infrastructure/graphql/types.ts`: `tier` resolves from `context.tier` (zero
read); `usage` is a **separate** resolver (a client asking only onboarding pays nothing) that
reads `monthlyUsage` + `trialUsage` (memoized, shared with a scan in the same request) +
`BeverageQuery.countByUser` (1 queryRead), caps from `context.tier`. Plain `Int` fields — no new
custom scalar (a new scalar generates a new iOS `CustomScalars/` file to commit).

**Tests**: `me { tier usage { ... } }` for free (trialRemaining, bottleCap 30) and pro
(enrichmentsCap 60, bottleCap null); assert read budget ≤ 3 reads.

New collections need no Firestore migration, no rules change (default-deny), and no composite
index.

### I1 — iOS `X-App-Build` header interceptor

`ios/Vinarium/Shared/AppBuildInterceptor.swift`: an `HTTPInterceptor` that sets `X-App-Build` =
`CFBundleVersion`; prepend it in `AuthenticatedInterceptorProvider.httpInterceptors`. Ship it in
the same release as the paywall so the header appears exactly when `QUOTA_ENFORCEMENT_MIN_BUILD`
is reached (harmless earlier — server ignores it below threshold).

### I2 — StoreKit 2 store + entitlement + JWS submit

**Product IDs**: group `Vinarium Pro`; `com.polyforms.vinarium.pro.monthly` (€4.99),
`com.polyforms.vinarium.pro.yearly` (€39.99).

**Xcode/project**: add a `Vinarium.storekit` config file (2 products, group) wired into the Run
scheme, add the **In-App Purchase** capability in `project.pbxproj`. **No `.entitlements`
change** (the IAP capability is provisioning-profile driven, so it won't force an App Store
version bump).

**Create** `ios/Vinarium/Features/Subscription/`
- `SubscriptionStore.swift` (`@MainActor @Observable`): `products` via `Product.products(for:)`;
  `purchase(_:)` → on `.success(.verified(transaction))` submit
  `verificationResult.jwsRepresentation`, `await transaction.finish()`; `restore()` =
  `try await AppStore.sync()` then resubmit `Transaction.currentEntitlements`; a
  `Transaction.updates` listener task started at launch that submits renewals.
- `EntitlementStore.swift` (`@MainActor @Observable`, app scope next to `AuthSession`;
  template = `AuthSession` / `AppSupportGate`): `enum Tier { free, pro }`,
  `private(set) var tier`. Source of truth = the ID-token custom claim; on change,
  `getIDTokenResult(forcingRefresh:)` reads `claims["tier"]`. After any successful
  `submitAppStoreTransaction`, call **`getIDTokenForcingRefresh(true)`** so the new claim is
  picked up immediately (without force-refresh it lags up to ~1h).
- `SubscriptionAPI.swift`: `enum` wrapper calling the new `SubmitAppStoreTransaction` mutation →
  returns tier; on success triggers `EntitlementStore.refreshFromToken()`.

**GraphQL** `ios/Vinarium/Features/Subscription/GraphQL/SubscriptionOperations.graphql`
(`submitAppStoreTransaction`, and a `me { tier usage { ... } }` query for paywall/settings).
**Add the new dir to `ios/apollo-codegen-config.json` `operationSearchPaths`.** Run
`bun run generate:graphql` then `cd ios && apollo-ios-cli generate` (the SPM-checkout binary),
commit the generated files. Prefer plain `Int`/`String` in SDL so no new CustomScalars are
generated.

**Wire** `EntitlementStore` / `SubscriptionStore` as `@State` in `AuthRoot.swift`,
`.environment(...)`, start the `Transaction.updates` listener in a `.task`.

### I3 — Paywall feature

`ios/Vinarium/Features/Paywall/` following the coordinator + previewable-`*Page` convention:
`PaywallView.swift` (coordinator), `components/pages/PaywallOfferPage.swift`,
`PaywallSuccessPage.swift`. **UI**: use **`SubscriptionStoreView`** (StoreKit SwiftUI) for the
offer surface — it renders localized prices, the required legal footer, and handles purchase,
cutting App-Review risk; wrap it with a custom marketing header/benefits. **Required for App
Review**: a visible **Restore** button (`AppStore.sync()`), **Terms (EULA)** and **Privacy**
links, and prices/period from the live `Product` (never hardcoded). French copy in the tone of
the existing screens (the app does address the user), never an em or en dash. **Triggers**:
`QUOTA_EXCEEDED` (scan), `BOTTLE_CAP_EXCEEDED` (add), and from Settings; present via `.sheet`
(matching `DashboardView`) or `.fullScreenCover` for the hard-block scan case.

### I4 — Gating UX + Settings + counters

Extend `ios/Vinarium/Shared/GraphQLHelpers.swift` `unwrap` to read
`errors.first?.extensions?["code"]` and throw a typed `APIError.domain(code:message:)` (add the
case) — this is the enabler for paywall triggering.

- **Scan flow** (`ScanViewModel.capturePhoto`, the sole `WineAPI.scan` caller): catch
  `APIError.domain(code: "QUOTA_EXCEEDED")` → set a `paywallReason` and present the Paywall
  instead of the generic error alert; other errors keep current behavior.
- **Add bottle**: wherever `addBeverage` is called, map `code: "BOTTLE_CAP_EXCEEDED"` → Paywall.
- **Settings** (`SettingsHomeView.swift`): new Section + `SettingsRow` + `NavigationLink` to a
  `SubscriptionSettingsView` (current plan from `me.tier`, usage from `me.usage`, Manage
  Subscription link, Restore button).
- **Counter**: optional small "X scans restants" from `me.usage.trialScansRemaining` on the scan
  entry screen for free users.

### Ops / release checklist & activation

**App Store Connect (manual, owner)**
- Create the subscription group `Vinarium Pro` and 2 auto-renewable products
  (`com.polyforms.vinarium.pro.monthly` €4.99, `.yearly` €39.99), localized descriptions, review
  screenshot.
- **Enroll in the Small Business Program** before launch (15% vs 30% — not automatic; every Q4
  net figure depends on it).
- Generate an **In-App Purchase key (.p8)** for the App Store Server API; note Key ID + Issuer ID.
- Configure the **App Store Server Notifications V2** production + sandbox URL →
  `https://<host>/webhooks/app-store`.
- Create sandbox testers. Add Terms of Use (EULA) + Privacy Policy URLs on the product page.

**Backend secrets** (4-file config pattern + terraform + tfvars in `deploy.yml`): add
`apple-iap-key` (.p8, reuse the Sign-in-with-Apple `.p8` injection pattern), `apple-iap-key-id`,
`apple-iap-issuer-id`, `apple-bundle-id`, `apple-app-apple-id` → `nitro.config.ts` runtimeConfig,
`server/system/config/{types,primitives,index}.ts`, `infra/secrets.tf` (`secret_values` +
`secret_ids` toset), `infra/variables.tf`, `.github/workflows/deploy.yml` tfvars. Env
auto-derives `NITRO_APPLE_IAP_KEY` etc.

**Deploy order** (all backend increments are dark)
1. Push B0→B5 to `main` (auto-deploy). Nothing enforces (no client sends `X-App-Build ≥
   threshold`, none submits a transaction); the webhook is live but idle.
2. Provision secrets + terraform apply; configure the ASSN webhook; verify a sandbox purchase
   drives `submitAppStoreTransaction` → claim → `me.tier == pro`.
3. Ship the iOS release (I1→I4). Its `CFBundleVersion` **is** `QUOTA_ENFORCEMENT_MIN_BUILD` — the
   moment it clears review and users update, enforcement activates for exactly those builds.
4. Later, independently, bump `MINIMUM_SUPPORTED_IOS_BUILD` (one line) to end the grace period
   for pre-paywall builds.

**Stays manual for the owner**: App Store Connect setup, Small Business enrollment, `.p8`/key
IDs, sandbox testers, terraform secret values, tagging the iOS release, and setting
`QUOTA_ENFORCEMENT_MIN_BUILD` to that release's build number.

### Risks & pitfalls

- **Breaking-change trap**: do not convert `scanBeverage`/`addBeverage` to unions — it breaks old
  clients and defeats the grace design. Coded errors only (decision 1).
- **App Review**: subscriptions require a Restore button, Terms + Privacy links, and live price
  display — `SubscriptionStoreView` gives these; a custom paywall must add them or risk rejection.
  The first IAP submission usually takes longer to review.
- **Custom-claim propagation latency**: `setCustomUserClaims` only lands in the token on refresh.
  iOS must `getIDTokenForcingRefresh(true)` after purchase, or the server keeps seeing `free` for
  up to ~1h. The webhook must rewrite the claim on every state change so expiry/renewal stays
  within one refresh cycle.
- **Webhook signature pitfalls**: always verify the JWS `x5c` chain to Apple Root CA G3 (don't
  just decode); pick the verifier matching the notification's environment; whitelist the route
  (no Firebase bearer); idempotency by `notificationUUID`; return 200 on success.
- **Sandbox limitations**: sandbox renewals are accelerated (minutes) and the environment
  differs; test both verifiers; sandbox `originalTransactionId` differs from production.
- **`scan-cache` × trial interplay**: a cache hit returns a full enriched result at zero cost and
  must not decrement the trial or monthly counters (metering only on a real Gemini call). A free
  vision-only user can still receive an enriched *cached* result — accepted as a rare, harmless
  upside.
- **peer-deps / node22**: confirm `@apple/app-store-server-library` installs cleanly under the
  strict-peer node22 pipeline (`npm ls jsonwebtoken`); fallback to `jose` + vendored root CA.
- **Cost hygiene** (from Q4): lower Sentry `tracesSampleRate` before growth; instrument
  `usageMetadata` in the scan refactor to recalibrate the caps and price against real
  `scan-usage`.
