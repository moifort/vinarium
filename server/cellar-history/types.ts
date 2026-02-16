import type { CellarCol, CellarRow } from '~/cellar/types'
import type { WineColor, WineId } from '~/wine/types'

export type CellarHistoryEntry = {
  wineId: WineId
  row: CellarRow
  col: CellarCol
  dateIn: Date
  dateOut?: Date
}

export type CellarHistoryEvent = {
  type: 'entry' | 'exit'
  date: Date
  wineId: string
  wineName: string
  wineColor: WineColor
  position: string
  rating?: number
  tastingNotes?: string
}
