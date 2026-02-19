import type { Brand } from 'ts-brand'
import type { CellarCol, CellarColLabel, CellarRow, CellarRowLabel } from '~/domain/cellar/types'
import type { JournalEventView } from '~/domain/journal/types'
import type { Country, Eur, Region, Year } from '~/domain/shared/types'
import type { Rating } from '~/domain/tasting/types'

export type WineId = Brand<string, 'WineId'>
export type WineName = Brand<string, 'WineName'>
export type WineDomain = Brand<string, 'WineDomain'>
export type Appellation = Brand<string, 'Appellation'>
export type Classification = Brand<string, 'Classification'>
export type WineColor = 'red' | 'white' | 'rosé' | 'sparkling' | 'sweet'

export type WineSort = 'vintage' | 'region' | 'color' | 'price'
export type SortOrder = 'asc' | 'desc'
export type WineStatus = 'in-cellar' | 'consumed' | 'all'

export type Wine = {
  id: WineId
  name: WineName
  color: WineColor
  domain?: WineDomain
  vintage?: Year
  appellation?: Appellation
  region?: Region
  country?: Country
  grapeVarieties?: string[]
  classification?: Classification
  purchasePrice?: Eur
  purchaseDate?: string
  drinkFrom?: Year
  drinkUntil?: Year
  imageBase64?: string
  notes?: string
  servingTemperature?: number
  createdAt: Date
  updatedAt: Date
}

export type WineView = Wine & {
  cellar?: {
    row: CellarRow
    col: CellarCol
    rowLabel: CellarRowLabel
    colLabel: CellarColLabel
    dateIn: Date
    dateOut?: Date
  }
  history: JournalEventView[]
  consumption?: {
    consumedDate?: Date
    rating?: Rating
    tastingNotes?: string
  }
}
