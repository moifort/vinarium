import type { CellarCol, CellarRow } from '~/domain/cellar/types'
import type { UserId } from '~/domain/shared/types'
import type { WineColor, WineId, WineName } from '~/domain/wine/types'

export type JournalEntryIn = {
  type: 'in'
  userId: UserId
  wineId: WineId
  row: CellarRow
  col: CellarCol
  date: Date
}

export type JournalEntryOut = {
  type: 'out'
  userId: UserId
  wineId: WineId
  row: CellarRow
  col: CellarCol
  date: Date
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
