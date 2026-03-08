import type { CellarCol, CellarRow } from '~/domain/cellar/types'
import type { WineColor, WineId, WineName } from '~/domain/wine/types'

export type JournalEntryIn = {
  type: 'in'
  wineId: WineId
  row: CellarRow
  col: CellarCol
  dateIn: Date
}

export type JournalEntryOut = {
  type: 'out'
  wineId: WineId
  row: CellarRow
  col: CellarCol
  dateOut: Date
}

export type JournalEntry = JournalEntryIn | JournalEntryOut

export type JournalEventView = {
  type: 'in' | 'out'
  date: Date
  wineId: WineId
  wineName: WineName
  wineColor: WineColor
  position: string
}
