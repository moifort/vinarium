import type { Brand } from 'ts-brand'
import type { WineId } from '~/wine/types'

export type CellarRows = Brand<number, 'CellarRows'>
export type CellarCols = Brand<number, 'CellarCols'>
export type CellarRow = Brand<number, 'CellarRow'>
export type CellarCol = Brand<number, 'CellarCol'>
export type CellarRowLabel = Brand<string, 'CellarRowLabel'>
export type CellarColLabel = Brand<number, 'CellarColLabel'>

export type CellarEntry = {
  wineId: WineId
  row: CellarRow
  col: CellarCol
  createdAt: Date
  updatedAt: Date
}

export type CellarEntryView = CellarEntry & {
  rowLabel: CellarRowLabel
  colLabel: CellarColLabel
}
