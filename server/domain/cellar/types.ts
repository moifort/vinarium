import type { Brand } from 'ts-brand'
import type { Beverage, BeverageId } from '~/domain/beverage/types'
import type { PersonName, UserId } from '~/domain/shared/types'

export type CellarRows = Brand<number, 'CellarRows'>
export type CellarCols = Brand<number, 'CellarCols'>
export type CellarZones = Brand<number, 'CellarZones'>
export type CellarRow = Brand<number, 'CellarRow'>
export type CellarCol = Brand<number, 'CellarCol'>
export type CellarRowLabel = Brand<string, 'CellarRowLabel'>
export type CellarColLabel = Brand<number, 'CellarColLabel'>
export type CellarId = Brand<string, 'CellarId'>
export type CellarName = Brand<string, 'CellarName'>

// `cellarId` names the grid the bottle stands in. Absent (every bottle placed
// before there could be several cellars), or naming a cellar the viewer's
// household does not hold (the owner joined or left a household since), it means
// the household's primary cellar: see `effectiveCellarId`.
export type CellarBottle = {
  userId: UserId
  beverageId: BeverageId
  cellarId?: CellarId
  row: CellarRow
  col: CellarCol
  createdAt: Date
  updatedAt: Date
}

export type CellarBottleView = CellarBottle & {
  rowLabel: CellarRowLabel
  colLabel: CellarColLabel
}

// A beverage paired with its owner — enough to read its bottle at the exact
// `${userId}_${id}` slot, no household scan (a bottle always sits at its owner's).
export type OwnedBeverage = { id: BeverageId; userId: UserId }

// Who a shared-cellar bottle belongs to. In a solo cellar every bottle is the
// viewer's own; in a household, bottles carry the owner's name for a badge.
export type CellarBottleOwner = {
  userId: UserId
  displayName?: PersonName
  isMine: boolean
}

// A placed bottle joined with the wine it holds and its owner — what the cave
// screen and the dashboard display side by side.
export type CellarBottleWithWine = CellarBottleView & {
  wine: Beverage
  owner: CellarBottleOwner
}

// A bottle read across the household's cellars, its cellar resolved: past this
// point `cellarId` is neither absent nor stale (see effectiveCellarId).
export type PlacedBottleWithWine = CellarBottleWithWine & { cellarId: CellarId }

// The physical dimensions of a cellar grid. `zones` records the cooler's
// temperature zones (1..3), captured at onboarding — stored for later use, not
// yet consumed by the grid.
export type CellarConfig = { rows: CellarRows; cols: CellarCols; zones: CellarZones }

// A cellar as stored. Every household (or solo account) has a primary cellar,
// keyed by its scope (`hh_<householdId>` or `usr_<userId>`), sized at onboarding
// and falling back to DEFAULT_CELLAR_SIZE until then — the document predates
// multiple cellars, so it may carry neither a name nor a scope. Every further
// cellar has a random id and records the scope it belongs to.
export type StoredCellar = CellarConfig & {
  scopeKey?: string
  name?: CellarName
  createdAt?: Date
}

// A cellar as the household sees it. An unnamed primary cellar is named by the
// app, in the reader's language.
export type Cellar = CellarConfig & {
  id: CellarId
  name?: CellarName
  isPrimary: boolean
}

// Premium buys more cellars, not unlimited ones: every cellar costs a read on
// each placement, so their number stays bounded.
export const MAX_CELLARS = 10

export const DEFAULT_CELLAR_SIZE = { rows: 6, cols: 8, zones: 1 } as const
