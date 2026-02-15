# Scan Enrichment, Universal Wine Detail, UI & Icon — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Gemini web search enrichment to wine scanning, create a universal wine detail sheet backed by an aggregator domain, add a Liquid Glass gallery button, and generate the app icon with Imagen 3.

**Architecture:** Backend gets a new `googleApiKey` config, a `AI.enrichWithSearch()` function using Gemini with Google Search grounding, and a new `UserWine` aggregator domain. iOS gets a universal `WineDetailSheet` replacing all detail views, and a restyled gallery button.

**Tech Stack:** Nitro 2.12.4, TypeScript, Zod, ts-brand, SwiftUI (iOS 26), Gemini API (grounding + Imagen 3)

---

## Task 1: Add Google API key to backend config

**Files:**
- Modify: `nitro.config.ts:4-6`
- Modify: `server/config/types.ts`
- Modify: `server/config/primitives.ts`
- Modify: `server/config/index.ts`

**Step 1: Add googleApiKey to nitro runtime config**

In `nitro.config.ts`, add `googleApiKey` to `runtimeConfig`:
```ts
runtimeConfig: {
  anthropicApiKey: '',
  googleApiKey: '',
},
```

**Step 2: Add branded type**

In `server/config/types.ts`, add:
```ts
export type GoogleApiKey = Brand<string, 'GoogleApiKey'>
```

**Step 3: Add validation primitive**

In `server/config/primitives.ts`, add import and function:
```ts
import type { GoogleApiKey as GoogleApiKeyType } from '~/config/types'

export const GoogleApiKey = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<GoogleApiKeyType>()(v)
}
```

**Step 4: Export from config**

In `server/config/index.ts`, add to the return object:
```ts
import { AnthropicApiKey, GoogleApiKey } from '~/config/primitives'

export const config = () => {
  const runtimeConfig = useRuntimeConfig()
  return {
    anthropicApiKey: AnthropicApiKey(runtimeConfig.anthropicApiKey),
    googleApiKey: GoogleApiKey(runtimeConfig.googleApiKey),
  }
}
```

**Step 5: Verify types compile**

Run: `cd /Users/thibaut/Code/cave-a-vin && npx nitro prepare && bun tsc --noEmit`
Expected: No errors

**Step 6: Commit**

```bash
git add nitro.config.ts server/config/
git commit -m "feat: add Google API key to backend config"
```

---

## Task 2: Add Gemini enrichment function to AI module

**Files:**
- Modify: `server/ai/index.ts`
- Modify: `server/ai/types.ts`

**Step 1: Add EnrichedScanResult type**

In `server/ai/types.ts`, the `ScanResult` type already has all needed fields. No new type needed — `enrichWithSearch` will return a `ScanResult` with improved values.

**Step 2: Add enrichWithSearch function**

In `server/ai/index.ts`, add inside the `AI` namespace after `scanLabel`:

```ts
const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent'

export const enrichWithSearch = async (scanResult: ScanResult): Promise<ScanResult> => {
  const { googleApiKey } = config()

  const wineDescription = [
    scanResult.name,
    scanResult.domain,
    scanResult.vintage ? `millésime ${scanResult.vintage}` : null,
    scanResult.appellation,
    scanResult.region,
    scanResult.country,
  ]
    .filter(Boolean)
    .join(', ')

  const prompt = `Recherche des informations sur ce vin : ${wineDescription}.

Donne-moi les informations suivantes au format JSON strict (sans markdown, juste le JSON) :
{
  "estimatedPrice": number ou null (prix moyen actuel en euros),
  "drinkFrom": number ou null (année à partir de laquelle boire),
  "drinkUntil": number ou null (année limite pour le boire),
  "grapeVarieties": string[] (cépages principaux),
  "region": string ou null (région viticole),
  "country": string ou null (pays),
  "classification": string ou null (classification officielle),
  "appellation": string ou null (appellation)
}

Utilise les données les plus récentes disponibles sur le web. Si tu ne trouves pas une information, mets null.`

  const response = await $fetch<{
    candidates: { content: { parts: { text?: string }[] } }[]
  }>(`${GEMINI_API_URL}?key=${googleApiKey}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: {
      contents: [{ parts: [{ text: prompt }] }],
      tools: [{ google_search: {} }],
    },
  })

  const text = response.candidates?.[0]?.content?.parts?.find((p) => p.text)?.text
  if (!text) return scanResult

  try {
    const jsonMatch = text.match(/\{[\s\S]*\}/)
    if (!jsonMatch) return scanResult
    const enriched = JSON.parse(jsonMatch[0])

    return {
      ...scanResult,
      estimatedPrice: enriched.estimatedPrice ?? scanResult.estimatedPrice,
      drinkFrom: enriched.drinkFrom ?? scanResult.drinkFrom,
      drinkUntil: enriched.drinkUntil ?? scanResult.drinkUntil,
      grapeVarieties:
        enriched.grapeVarieties?.length > 0 ? enriched.grapeVarieties : scanResult.grapeVarieties,
      region: enriched.region ?? scanResult.region,
      country: enriched.country ?? scanResult.country,
      classification: enriched.classification ?? scanResult.classification,
      appellation: enriched.appellation ?? scanResult.appellation,
    }
  } catch {
    return scanResult
  }
}
```

**Step 3: Verify types compile**

Run: `cd /Users/thibaut/Code/cave-a-vin && bun tsc --noEmit`
Expected: No errors

**Step 4: Commit**

```bash
git add server/ai/
git commit -m "feat: add Gemini web search enrichment for wine scan"
```

---

## Task 3: Wire enrichment into scan route

**Files:**
- Modify: `server/routes/wines/scan.post.ts`

**Step 1: Update scan route to call enrichWithSearch**

Replace `server/routes/wines/scan.post.ts` content with:
```ts
import { AI } from '~/ai/index'

export default defineEventHandler(async (event) => {
  const body = await readRawBody(event, false)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'No image provided' })

  const scanResult = await AI.scanLabel(Buffer.from(body))
  const enriched = await AI.enrichWithSearch(scanResult)

  return { status: 200, data: enriched }
})
```

**Step 2: Verify types compile**

Run: `cd /Users/thibaut/Code/cave-a-vin && bun tsc --noEmit`
Expected: No errors

**Step 3: Commit**

```bash
git add server/routes/wines/scan.post.ts
git commit -m "feat: wire Gemini enrichment into wine scan route"
```

---

## Task 4: Create UserWine aggregator domain (backend)

**Files:**
- Create: `server/user-wine/types.ts`
- Create: `server/user-wine/index.ts`
- Create: `server/routes/user-wine/[id].get.ts`

**Step 1: Create UserWine types**

Create `server/user-wine/types.ts`:
```ts
import type { WineColor } from '~/wine/types'

export type UserWineDetail = {
  id: string
  name: string
  color: WineColor
  domain: string | null
  vintage: number | null
  appellation: string | null
  region: string | null
  country: string | null
  grapeVarieties: string[]
  alcoholContent: number | null
  classification: string | null
  purchasePrice: number | null
  purchaseDate: string | null
  drinkFrom: number | null
  drinkUntil: number | null
  notes: string | null
  createdAt: Date
  updatedAt: Date
  cellar: {
    row: string
    col: number
    dateIn: Date
  } | null
  consumption: {
    dateOut: Date
    consumedDate: Date | null
    rating: number | null
    tastingNotes: string | null
  } | null
}
```

**Step 2: Create UserWine namespace**

Create `server/user-wine/index.ts`:
```ts
import { Cellar } from '~/cellar/index'
import type { WineId } from '~/wine/types'
import { Wines } from '~/wine/index'
import type { UserWineDetail } from '~/user-wine/types'

export namespace UserWine {
  export const getDetail = async (wineId: WineId): Promise<UserWineDetail | 'not-found'> => {
    const wine = await Wines.getById(wineId)
    if (wine === 'not-found') return 'not-found'

    const entry = await Cellar.getEntryByWineId(wineId)

    let cellar: UserWineDetail['cellar'] = null
    let consumption: UserWineDetail['consumption'] = null

    if (entry && !entry.dateOut) {
      cellar = {
        row: entry.row as string,
        col: entry.col as number,
        dateIn: entry.dateIn,
      }
    } else if (entry?.dateOut) {
      consumption = {
        dateOut: entry.dateOut,
        consumedDate: entry.consumedDate ?? null,
        rating: entry.rating != null ? (entry.rating as number) : null,
        tastingNotes: entry.tastingNotes ?? null,
      }
    }

    return {
      id: wine.id as string,
      name: wine.name as string,
      color: wine.color,
      domain: wine.domain ?? null,
      vintage: wine.vintage != null ? (wine.vintage as number) : null,
      appellation: wine.appellation ?? null,
      region: wine.region != null ? (wine.region as string) : null,
      country: wine.country != null ? (wine.country as string) : null,
      grapeVarieties: wine.grapeVarieties ?? [],
      alcoholContent: wine.alcoholContent != null ? (wine.alcoholContent as number) : null,
      classification: wine.classification ?? null,
      purchasePrice: wine.purchasePrice != null ? (wine.purchasePrice as number) : null,
      purchaseDate: wine.purchaseDate ?? null,
      drinkFrom: wine.drinkFrom != null ? (wine.drinkFrom as number) : null,
      drinkUntil: wine.drinkUntil != null ? (wine.drinkUntil as number) : null,
      notes: wine.notes ?? null,
      createdAt: wine.createdAt,
      updatedAt: wine.updatedAt,
      cellar,
      consumption,
    }
  }
}
```

**Step 3: Create route**

Create `server/routes/user-wine/[id].get.ts`:
```ts
import { UserWine } from '~/user-wine/index'
import { WineId } from '~/wine/primitives'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const detail = await UserWine.getDetail(id)
  if (detail === 'not-found') {
    throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  }
  return { status: 200, data: detail }
})
```

**Step 4: Verify types compile**

Run: `cd /Users/thibaut/Code/cave-a-vin && npx nitro prepare && bun tsc --noEmit`
Expected: No errors

**Step 5: Commit**

```bash
git add server/user-wine/ server/routes/user-wine/
git commit -m "feat: add UserWine aggregator domain with detail endpoint"
```

---

## Task 5: iOS — Add UserWineDetail model and API

**Files:**
- Create: `ios/CaveAVin/Models/UserWineDetail.swift`
- Create: `ios/CaveAVin/API/UserWineAPI.swift`

**Step 1: Create UserWineDetail model**

Create `ios/CaveAVin/Models/UserWineDetail.swift`:
```swift
import Foundation

struct UserWineDetail: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let color: WineColor
    let domain: String?
    let vintage: Int?
    let appellation: String?
    let region: String?
    let country: String?
    let grapeVarieties: [String]
    let alcoholContent: Double?
    let classification: String?
    let purchasePrice: Double?
    let purchaseDate: String?
    let drinkFrom: Int?
    let drinkUntil: Int?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    let cellar: CellarInfo?
    let consumption: ConsumptionInfo?
}

struct CellarInfo: Codable, Sendable {
    let row: String
    let col: Int
    let dateIn: Date
}

struct ConsumptionInfo: Codable, Sendable {
    let dateOut: Date
    let consumedDate: Date?
    let rating: Int?
    let tastingNotes: String?
}
```

**Step 2: Create UserWineAPI**

Create `ios/CaveAVin/API/UserWineAPI.swift`:
```swift
import Foundation

enum UserWineAPI {
    static func get(id: String) async throws -> UserWineDetail {
        let response: APIResponse<UserWineDetail> = try await APIClient.shared.get("/user-wine/\(id)")
        return response.data
    }
}
```

**Step 3: Verify iOS build**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/CaveAVin.xcodeproj -scheme CaveAVin -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add ios/CaveAVin/Models/UserWineDetail.swift ios/CaveAVin/API/UserWineAPI.swift
git commit -m "feat(ios): add UserWineDetail model and API client"
```

---

## Task 6: iOS — Create universal WineDetailSheet

**Files:**
- Create: `ios/CaveAVin/Shared/WineDetailSheet.swift`

**Step 1: Create WineDetailSheet**

Create `ios/CaveAVin/Shared/WineDetailSheet.swift`. This sheet loads data from the UserWine aggregator endpoint and displays the full wine detail. It replaces both `CellDetailSheet` and `WineDetailView` as the single comprehensive detail view.

```swift
import SwiftUI

struct WineDetailSheet: View {
    let wineId: String
    var onRemoved: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var detail: UserWineDetail?
    @State private var isLoading = true
    @State private var error: String?
    @State private var showConsumption = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if let detail {
                    wineContent(detail)
                } else if let error {
                    ContentUnavailableView("Erreur", systemImage: "exclamationmark.triangle", description: Text(error))
                }
            }
            .navigationTitle(detail?.name ?? "Détail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .task { await loadData() }
        }
    }

    @ViewBuilder
    private func wineContent(_ detail: UserWineDetail) -> some View {
        List {
            // Header
            Section {
                HStack(spacing: 12) {
                    WineColorBadge(color: detail.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(detail.name)
                            .font(.headline)
                        Text(detail.color.label)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if let domain = detail.domain {
                    Label {
                        LabeledContent("Domaine", value: domain)
                    } icon: {
                        Image(systemName: "building.2")
                            .foregroundStyle(.secondary)
                    }
                }
                if let vintage = detail.vintage {
                    Label {
                        LabeledContent("Millésime", value: "\(vintage)")
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Origine
            if detail.appellation != nil || detail.region != nil || detail.country != nil || detail.classification != nil {
                Section("Origine") {
                    if let appellation = detail.appellation {
                        Label {
                            LabeledContent("Appellation", value: appellation)
                        } icon: {
                            Image(systemName: "seal")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let region = detail.region {
                        Label {
                            LabeledContent("Région", value: region)
                        } icon: {
                            Image(systemName: "map")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let country = detail.country {
                        Label {
                            LabeledContent("Pays", value: country)
                        } icon: {
                            Image(systemName: "globe.europe.africa")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let classification = detail.classification {
                        Label {
                            LabeledContent("Classification", value: classification)
                        } icon: {
                            Image(systemName: "rosette")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Détails
            if detail.alcoholContent != nil || detail.purchasePrice != nil || !detail.grapeVarieties.isEmpty {
                Section("Détails") {
                    if let alcohol = detail.alcoholContent {
                        Label {
                            LabeledContent("Alcool", value: String(format: "%.1f %% vol", alcohol))
                        } icon: {
                            Image(systemName: "drop")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let price = detail.purchasePrice {
                        Label {
                            LabeledContent("Prix d'achat", value: String(format: "%.0f €", price))
                        } icon: {
                            Image(systemName: "eurosign.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let date = detail.purchaseDate {
                        Label {
                            LabeledContent("Date d'achat", value: date)
                        } icon: {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !detail.grapeVarieties.isEmpty {
                        Label {
                            LabeledContent("Cépages", value: detail.grapeVarieties.joined(separator: ", "))
                        } icon: {
                            Image(systemName: "leaf")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Garde
            if detail.drinkFrom != nil || detail.drinkUntil != nil {
                Section("Garde") {
                    if let from = detail.drinkFrom {
                        Label {
                            LabeledContent("À partir de", value: "\(from)")
                        } icon: {
                            Image(systemName: "hourglass.bottomhalf.filled")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let until = detail.drinkUntil {
                        Label {
                            LabeledContent("Jusqu'à", value: "\(until)")
                        } icon: {
                            Image(systemName: "hourglass.tophalf.filled")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // En cave
            if let cellar = detail.cellar {
                Section("En cave") {
                    Label {
                        LabeledContent("Position", value: "\(cellar.row)\(cellar.col)")
                    } icon: {
                        Image(systemName: "mappin.circle")
                            .foregroundStyle(.blue)
                    }
                    Label {
                        LabeledContent("Depuis", value: formatted(cellar.dateIn))
                    } icon: {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundStyle(.green)
                    }

                    Button(role: .destructive) {
                        showConsumption = true
                    } label: {
                        Label("Retirer de la cave", systemImage: "arrow.up.circle")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }

            // Consommé
            if let consumption = detail.consumption {
                Section("Consommé") {
                    Label {
                        LabeledContent("Retiré le", value: formatted(consumption.dateOut))
                    } icon: {
                        Image(systemName: "calendar.badge.minus")
                            .foregroundStyle(.red)
                    }
                    if let rating = consumption.rating {
                        HStack {
                            Label("Note", systemImage: "star")
                                .foregroundStyle(.secondary)
                            Spacer()
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundStyle(star <= rating ? .yellow : .gray)
                                    .font(.caption)
                            }
                        }
                    }
                    if let notes = consumption.tastingNotes {
                        Label {
                            Text(notes)
                        } icon: {
                            Image(systemName: "note.text")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Notes
            if let notes = detail.notes, !notes.isEmpty {
                Section("Notes") {
                    Label {
                        Text(notes)
                    } icon: {
                        Image(systemName: "note.text")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showConsumption) {
            if let detail {
                ConsumptionSheet(wine: Wine(
                    id: detail.id,
                    name: detail.name,
                    color: detail.color,
                    createdAt: detail.createdAt,
                    updatedAt: detail.updatedAt
                )) { date, rating, notes in
                    let formatter = ISO8601DateFormatter()
                    Task {
                        _ = try? await CellarAPI.remove(
                            wineId: detail.id,
                            consumedDate: formatter.string(from: date),
                            rating: rating,
                            tastingNotes: notes
                        )
                        showConsumption = false
                        dismiss()
                        onRemoved?()
                    }
                }
            }
        }
    }

    private func loadData() async {
        do {
            detail = try await UserWineAPI.get(id: wineId)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    private func formatted(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
```

**Step 2: Verify iOS build**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/CaveAVin.xcodeproj -scheme CaveAVin -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add ios/CaveAVin/Shared/WineDetailSheet.swift
git commit -m "feat(ios): add universal WineDetailSheet component"
```

---

## Task 7: iOS — Wire WineDetailSheet into all views

**Files:**
- Modify: `ios/CaveAVin/Features/WineList/WineListView.swift`
- Modify: `ios/CaveAVin/Features/Dashboard/DashboardView.swift`
- Modify: `ios/CaveAVin/Features/Cellar/CellarGridView.swift`
- Modify: `ios/CaveAVin/Features/Cellar/CellarJournalView.swift`
- Delete: `ios/CaveAVin/Features/WineList/WineDetailView.swift`
- Delete: `ios/CaveAVin/Features/Cellar/CellDetailSheet.swift`

**Step 1: Update WineListView**

Replace the `NavigationLink` pattern with a sheet. Replace the `List` content and remove `.navigationDestination`:

```swift
// In WineListView, add @State:
@State private var selectedWineId: String?

// Replace the List content — change NavigationLink to Button:
List(viewModel.wines) { wine in
    Button {
        selectedWineId = wine.id
    } label: {
        HStack {
            WineColorBadge(color: wine.color)
            VStack(alignment: .leading) {
                Text(wine.name)
                    .font(.headline)
                HStack(spacing: 4) {
                    if let vintage = wine.vintage {
                        Text("\(vintage)")
                    }
                    if let region = wine.region {
                        Text("- \(region)")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if let price = wine.purchasePrice {
                Text(String(format: "%.0f €", price))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    .tint(.primary)
}

// Remove .navigationDestination(for: String.self) { ... }
// Add .sheet after .toolbar:
.sheet(item: $selectedWineId.asBinding) { wineId in
    WineDetailSheet(wineId: wineId)
}
```

Note: Since `String` doesn't conform to `Identifiable`, use a small wrapper or a different binding approach. The simplest is to use `.sheet(isPresented:)` with an `onChange`:

Actually, use this pattern instead — replace `.navigationDestination` and add:
```swift
@State private var selectedWineId: String?

// Add after .toolbar:
.sheet(item: Binding(
    get: { selectedWineId.map { WineIdWrapper(id: $0) } },
    set: { selectedWineId = $0?.id }
)) { wrapper in
    WineDetailSheet(wineId: wrapper.id)
}
```

With a small helper (add at file level):
```swift
private struct WineIdWrapper: Identifiable {
    let id: String
}
```

**Step 2: Update DashboardView**

Add `@State private var selectedWineId: String?` and the same sheet binding.

Make `readyToDrinkSection` wines tappable:
```swift
ForEach(wines) { wine in
    Button {
        selectedWineId = wine.id
    } label: {
        HStack {
            WineColorBadge(color: wine.color)
            Text(wine.name)
            Spacer()
            if let vintage = wine.vintage {
                Text("\(vintage)")
                    .foregroundStyle(.secondary)
            }
        }
    }
    .tint(.primary)
}
```

Make activity cards tappable — wrap `activityCard` in a `Button`:
```swift
if let entry = data.lastEntry {
    Button { selectedWineId = entry.wine.id } label: {
        activityCard(icon: "arrow.down.circle.fill", iconColor: .green, title: "Dernière entrée", wine: entry.wine, date: entry.date, position: entry.position)
    }
    .tint(.primary)
}
```

Same for `lastExit`.

Add `.sheet` after `.task`:
```swift
.sheet(item: Binding(
    get: { selectedWineId.map { WineIdWrapper(id: $0) } },
    set: { selectedWineId = $0?.id }
)) { wrapper in
    WineDetailSheet(wineId: wrapper.id)
}
```

Add `WineIdWrapper` at file level.

**Step 3: Update CellarGridView**

Replace `@State private var selectedCell: CellSelection?` with `@State private var selectedWineId: String?`.

In `caveListContent`, change the Button action:
```swift
Button {
    selectedWineId = item.wine.id
} label: { ... }
```

Replace the `.sheet(item: $selectedCell)` with:
```swift
.sheet(item: Binding(
    get: { selectedWineId.map { WineIdWrapper(id: $0) } },
    set: { selectedWineId = $0?.id }
)) { wrapper in
    WineDetailSheet(wineId: wrapper.id) {
        Task { await viewModel.load() }
    }
}
```

Remove `CellSelection` struct. Add `WineIdWrapper`.

**Step 4: Update CellarJournalView**

Add `@State private var selectedWineId: String?` and wrap `eventRow` in a `Button`:
```swift
ForEach(group.events) { event in
    Button {
        selectedWineId = event.wineId
    } label: {
        eventRow(event)
    }
    .tint(.primary)
}
```

Add `.sheet` modifier on the `List`.

**Step 5: Delete old files**

Delete `ios/CaveAVin/Features/WineList/WineDetailView.swift` and `ios/CaveAVin/Features/Cellar/CellDetailSheet.swift`.

**Step 6: Verify iOS build**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/CaveAVin.xcodeproj -scheme CaveAVin -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 7: Commit**

```bash
git add -A ios/CaveAVin/
git commit -m "feat(ios): wire WineDetailSheet into all views, remove old detail views"
```

---

## Task 8: iOS — Liquid Glass gallery button in scan view

**Files:**
- Modify: `ios/CaveAVin/ContentView.swift`

**Step 1: Replace the PhotosPicker style**

In `ContentView.swift`, in the `ScanFlowView` `.camera` case, replace the current PhotosPicker block:

```swift
// OLD:
PhotosPicker(
    selection: $selectedPhoto,
    matching: .images
) {
    Label("Galerie", systemImage: "photo.on.rectangle")
        .font(.callout)
        .fontWeight(.medium)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
}
.padding(.leading)
.padding(.bottom, 100)

// NEW:
PhotosPicker(
    selection: $selectedPhoto,
    matching: .images
) {
    Image(systemName: "photo")
        .font(.title2)
        .frame(width: 44, height: 44)
}
.glassEffect(.regular, in: .circle)
.padding(.leading)
.padding(.bottom, 100)
```

**Step 2: Verify iOS build**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/CaveAVin.xcodeproj -scheme CaveAVin -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add ios/CaveAVin/ContentView.swift
git commit -m "feat(ios): liquid glass round button for photo gallery in scan view"
```

---

## Task 9: Generate app icon with Imagen 3

**Files:**
- Modify: `ios/CaveAVin/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `ios/CaveAVin/Assets.xcassets/AppIcon.appiconset/AppIcon.png`

**Step 1: Generate the icon image**

Run a curl command to call the Gemini API with image generation:

```bash
curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp-image-generation:generateContent?key=AIzaSyAu5YQ-sj7WenSI89chvybCCH7sz_VKj34" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "parts": [{
        "text": "Generate a beautiful iOS app icon (1024x1024, no text, no transparency). View from directly above of wine bottles arranged in a staggered/quinconce pattern. The bottles are seen from the top, showing the cork/capsule ends in various rich wine colors (deep red, burgundy, gold). Clean, modern, minimalist style suitable for an iOS app icon. Solid background, vibrant colors, no text overlay."
      }]
    }],
    "generationConfig": {
      "responseModalities": ["TEXT", "IMAGE"]
    }
  }' | python3 -c "
import sys, json, base64
data = json.load(sys.stdin)
for part in data['candidates'][0]['content']['parts']:
    if 'inlineData' in part:
        img = base64.b64decode(part['inlineData']['data'])
        with open('ios/CaveAVin/Assets.xcassets/AppIcon.appiconset/AppIcon.png', 'wb') as f:
            f.write(img)
        print('Icon saved!')
        break
"
```

If the model name doesn't work, try `gemini-2.5-flash-preview-image-generation` instead.

**Step 2: Update Contents.json**

Update `ios/CaveAVin/Assets.xcassets/AppIcon.appiconset/Contents.json`:
```json
{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

**Step 3: Verify the icon is a valid PNG and 1024x1024**

Run: `file ios/CaveAVin/Assets.xcassets/AppIcon.appiconset/AppIcon.png && sips -g pixelHeight -g pixelWidth ios/CaveAVin/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
Expected: PNG image, 1024x1024

**Step 4: Verify iOS build**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/CaveAVin.xcodeproj -scheme CaveAVin -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add ios/CaveAVin/Assets.xcassets/AppIcon.appiconset/
git commit -m "feat(ios): add generated app icon with wine bottles pattern"
```

---

## Task 10: Final verification

**Step 1: Full backend type check**

Run: `cd /Users/thibaut/Code/cave-a-vin && npx nitro prepare && bun tsc --noEmit`
Expected: No errors

**Step 2: Full iOS build**

Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/CaveAVin.xcodeproj -scheme CaveAVin -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

**Step 3: Commit (if any fixes needed)**

```bash
git add -A && git commit -m "fix: resolve build issues from final verification"
```
