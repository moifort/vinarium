import type { CellarColLabel, CellarRowLabel } from '~/cellar/types'
import type { WineColor, WineId, WineName } from '~/wine/types'

export type CellarLogEntryIn = {
  type: 'in'
  wineId: WineId
  rowLabel: CellarRowLabel
  colLabel: CellarColLabel
  dateIn: Date
}

export type CellarLogEntryOut = {
  type: 'out'
  wineId: WineId
  rowLabel: CellarRowLabel
  colLabel: CellarColLabel
  dateOut: Date
}

export type CellarLogEntry = CellarLogEntryIn | CellarLogEntryOut

export type CellarLogEventView = {
  type: 'in' | 'out'
  date: Date
  wineId: WineId
  wineName: WineName
  wineColor: WineColor
  position: string
}
