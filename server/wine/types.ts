import type { Brand } from 'ts-brand'
import type { CellarCol, CellarColLabel, CellarRow, CellarRowLabel } from '~/cellar/types'
import type { CellarLogEventView } from '~/cellar-log/types'
import type { Rating } from '~/tasting/types'
import type { Country, Eur, Region, Year } from '~/types'

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
  createdAt: Date
  updatedAt: Date
}

export type WineView = Wine & {
  cellar?: {
    row: CellarRow
    col: CellarCol
    rowLabel: CellarRowLabel
    colLabel: CellarColLabel
    createdAt: Date
  }
  history: CellarLogEventView[]
  consumption?: {
    consumedDate?: Date
    rating?: Rating
    tastingNotes?: string
  }
}
