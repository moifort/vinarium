import type { BeverageId, BeverageName, BeverageType, WineColor } from '~/domain/beverage/types'
import type { CellarCol, CellarRow } from '~/domain/cellar/types'
import type { PersonName, UserId } from '~/domain/shared/types'

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

// Who moved the bottle, as seen by the viewer: their own events carry no name
// (the UI omits the badge), a housemate's event carries theirs.
export type JournalEventActor = {
  userId: UserId
  displayName?: PersonName
  isMine: boolean
}

export type JournalEventView = {
  type: 'in' | 'out'
  date: Date
  beverageId: BeverageId
  beverageName: BeverageName
  wineBeverageType: BeverageType
  wineColor?: WineColor
  position: string
  actor: JournalEventActor
}
