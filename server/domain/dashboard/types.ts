import type {
  Appellation,
  BeverageId,
  BeverageName,
  BeverageSubtype,
  BeverageType,
  Classification,
  LabelFamily,
  Notes,
  Producer,
  WineColor,
} from '~/domain/beverage/types'
import type { CellarId } from '~/domain/cellar/types'
import type { JournalEventView } from '~/domain/journal/types'
import type { Eur, Year } from '~/domain/shared/types'

export type DashboardView = {
  bottleCount: number
  capacity: number
  totalValue: number
  readyToDrink: ReadyToDrinkWine[]
  // How many bottles are ready and how many wines are favorites in all, the
  // shortlists above being capped.
  readyToDrinkCount: number
  favoriteCount: number
  favorites: FavoriteWine[]
  lastBottle?: LastBottle
  lastExit?: JournalEventView
  history: JournalEventView[]
}

export type FavoriteWine = {
  id: BeverageId
  name: BeverageName
  beverageType: BeverageType
  subtype?: BeverageSubtype
  producer?: Producer
  color?: WineColor
  vintage?: Year
  appellation?: Appellation
  classification?: Classification
  labelFamily: LabelFamily
  estimatedPrice?: Eur
  tastingDate?: Date
  rating?: number
  // Where the wine stands when it is in the household's cellars: its own bottle,
  // else one identical to it. Absent once every such bottle is gone.
  cellarId?: CellarId
  position?: string
  drinkUntil?: Year
  // How many identical bottles the household's cellars hold (see sameWineKey).
  stock: number
}

export type ReadyToDrinkWine = {
  id: BeverageId
  name: BeverageName
  beverageType: BeverageType
  subtype?: BeverageSubtype
  producer?: Producer
  color?: WineColor
  vintage?: Year
  appellation?: Appellation
  classification?: Classification
  labelFamily: LabelFamily
  notes?: Notes
  // Whether the viewer flagged this wine as a favorite.
  isFavorite: boolean
  cellarId: CellarId
  position: string
  urgent: boolean
  drinkUntil?: Year
  estimatedPrice?: Eur
  // How many identical bottles the household's cellars hold (see sameWineKey).
  stock: number
}

export type LastBottle = {
  wine: {
    id: BeverageId
    name: BeverageName
    beverageType: BeverageType
    color?: WineColor
    vintage?: Year
  }
  cellarId: CellarId
  position: string
  date: Date
}
