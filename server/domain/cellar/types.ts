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

export type CellarBottle = {
  userId: UserId
  beverageId: BeverageId
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

// The physical dimensions of a shared cellar grid, set during onboarding and
// keyed by cellar scope (household or solo). Falls back to DEFAULT_CELLAR_SIZE
// until configured. `zones` records the cooler's temperature zones (1..3),
// captured at onboarding — stored for later use, not yet consumed by the grid.
export type CellarConfig = { rows: CellarRows; cols: CellarCols; zones: CellarZones }

export const DEFAULT_CELLAR_SIZE = { rows: 6, cols: 8, zones: 1 } as const
