import type { JournalEventView } from '~/domain/journal/types'
import type { Eur, Year } from '~/domain/shared/types'
import type { WineColor, WineId, WineName } from '~/domain/wine/types'

export type DashboardView = {
  bottleCount: number
  totalValue: number
  readyToDrink: ReadyToDrinkWine[]
  favorites: FavoriteWine[]
  shortlist: ShortlistWine[]
  lastBottle?: LastBottle
  lastExit?: JournalEventView
  history: JournalEventView[]
}

export type FavoriteWine = {
  id: WineId
  name: WineName
  color: WineColor
  vintage?: Year
  estimatedPrice?: Eur
  tastingDate?: Date
}

export type ShortlistWine = {
  id: WineId
  name: WineName
  color: WineColor
  vintage?: Year
  estimatedPrice?: Eur
  tastingDate?: Date
  rating?: number
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
