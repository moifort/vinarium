import type { BeverageId, BeverageName, BeverageType, WineColor } from '~/domain/beverage/types'
import type { CellarCol, CellarRow } from '~/domain/cellar/types'
import type { UserId } from '~/domain/shared/types'

export type JournalEntryIn = {
  type: 'in'
  userId: UserId
  beverageId: BeverageId
  row: CellarRow
  col: CellarCol
  date: Date
}

export type JournalEntryOut = {
  type: 'out'
  userId: UserId
  beverageId: BeverageId
  row: CellarRow
  col: CellarCol
  date: Date
}

export type JournalEntry = JournalEntryIn | JournalEntryOut

export type JournalEventView = {
  type: 'in' | 'out'
  date: Date
  beverageId: BeverageId
  beverageName: BeverageName
  wineBeverageType: BeverageType
  wineColor?: WineColor
  position: string
}
