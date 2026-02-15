# Plan: 3 Fixes

## Fix 1: Stats page shows nothing / doesn't refresh

**Root cause**: `.task` only runs once. When user adds a bottle then switches to Stats tab, data is stale. Also needs to reload on every tab switch.

**Changes:**
- `StatsView.swift` — replace `.task` with `.onAppear` to reload every time tab is selected
- Also add a fallback empty state if no bottles are in cellar

## Fix 2: Cellar config for DE DIETRICH DUW46DFB

46 bottles, 5 shelves → grid approximation: **6 rows × 8 cols** (48 positions)

**Change:**
- `server/cellar/index.ts` — update `DEFAULT_CONFIG` to 6×8, name "DE DIETRICH DUW46DFB"

## Fix 3: Rating filter in wine list

Rating is on `CellarEntry`. Need to cross-reference.

**Backend:**
- `server/wine/index.ts` — add `minRating` param, filter consumed wines by rating from cellar entries
- `server/routes/wines/index.get.ts` — parse `minRating` query param

**iOS:**
- `WineListViewModel.swift` — add `minRating` state
- `WineListView.swift` — add rating picker in toolbar
- `WineAPI.swift` — pass `minRating`

## Verification
- `bun tsc --noEmit` + xcodebuild, then commit
