import type { Brand } from 'ts-brand'
import type { WineId } from '~/wine/types'

export type CellarRows = Brand<number, 'CellarRows'>
export type CellarCols = Brand<number, 'CellarCols'>
export type CellarRow = Brand<string, 'CellarRow'>
export type CellarCol = Brand<number, 'CellarCol'>

export type CellarConfig = {
  rows: CellarRows
  cols: CellarCols
  name: string
}

export type CellarEntry = {
  wineId: WineId
  row: CellarRow
  col: CellarCol
  dateIn: Date
  dateOut: Date | null
}
