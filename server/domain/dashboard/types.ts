import type { BeverageId, BeverageName, BeverageType, WineColor } from '~/domain/beverage/types'
import type { JournalEventView } from '~/domain/journal/types'
import type { Eur, Year } from '~/domain/shared/types'

export type DashboardView = {
  bottleCount: number
  capacity: number
  totalValue: number
  readyToDrink: ReadyToDrinkWine[]
  favorites: FavoriteWine[]
  lastBottle?: LastBottle
  lastExit?: JournalEventView
  history: JournalEventView[]
}

export type FavoriteWine = {
  id: BeverageId
  name: BeverageName
  beverageType: BeverageType
  color?: WineColor
  vintage?: Year
  estimatedPrice?: Eur
  tastingDate?: Date
  rating?: number
}

export type ReadyToDrinkWine = {
  id: BeverageId
  name: BeverageName
  beverageType: BeverageType
  color?: WineColor
  position: string
  urgent: boolean
  drinkUntil?: Year
}

export type LastBottle = {
  wine: {
    id: BeverageId
    name: BeverageName
    beverageType: BeverageType
    color?: WineColor
    vintage?: Year
  }
  position: string
  date: Date
}
