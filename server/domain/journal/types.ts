import type { CellarColLabel, CellarRowLabel } from '~/domain/cellar/types'
import type { WineColor, WineId, WineName } from '~/domain/wine/types'

export type JournalEntryIn = {
  type: 'in'
  wineId: WineId
  rowLabel: CellarRowLabel
  colLabel: CellarColLabel
  dateIn: Date
}

export type JournalEntryOut = {
  type: 'out'
  wineId: WineId
  rowLabel: CellarRowLabel
  colLabel: CellarColLabel
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
