import type { CellarLogEventView } from '~/cellar-log/types'
import type { Region, Year } from '~/shared/types'
import type { Appellation, WineColor, WineDomain, WineId, WineName } from '~/wine/types'

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
  domain?: WineDomain
  vintage?: Year
  region?: Region
  appellation?: Appellation
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
