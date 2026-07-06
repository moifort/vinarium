import type { Brand } from 'ts-brand'
import type { UserId } from '~/domain/shared/types'
import type { Wine, WineId } from '~/domain/wine/types'

export type CellarRows = Brand<number, 'CellarRows'>
export type CellarCols = Brand<number, 'CellarCols'>
export type CellarRow = Brand<number, 'CellarRow'>
export type CellarCol = Brand<number, 'CellarCol'>
export type CellarRowLabel = Brand<string, 'CellarRowLabel'>
export type CellarColLabel = Brand<number, 'CellarColLabel'>

export type CellarBottle = {
  userId: UserId
  wineId: WineId
  row: CellarRow
  col: CellarCol
  createdAt: Date
  updatedAt: Date
}

export type CellarBottleView = CellarBottle & {
  rowLabel: CellarRowLabel
  colLabel: CellarColLabel
}

// A placed bottle joined with the wine it holds — what the cave screen and the
// dashboard display side by side.
export type CellarBottleWithWine = CellarBottleView & { wine: Wine }

export const CELLAR_SIZE = { rows: 6, cols: 8 } as const
