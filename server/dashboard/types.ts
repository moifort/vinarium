import type { CellarLogEventView } from '~/cellar-log/types'
import type { Year } from '~/shared/types'
import type { WineColor, WineId, WineName } from '~/wine/types'

export type DashboardView = {
  bottleCount: number
  totalValue: number
  readyToDrink: ReadyToDrinkWine[]
  lastBottle?: LastBottle
  lastExit?: CellarLogEventView
  history: CellarLogEventView[]
}

export type ReadyToDrinkWine = {
  id: WineId
  name: WineName
  color: WineColor
  position: string
  urgent: boolean
  drinkUntil?: Year
}

export type LastBottle = {
  wine: {
    id: WineId
    name: WineName
    color: WineColor
    vintage?: Year
  }
  position: string
  date: Date
}
