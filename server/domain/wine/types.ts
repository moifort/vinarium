import type { Brand } from 'ts-brand'
import type {
  Country,
  Eur,
  Latitude,
  Longitude,
  PersonName,
  PlaceName,
  Region,
  UserId,
  Year,
} from '~/domain/shared/types'

export type WineId = Brand<string, 'WineId'>
export type WineName = Brand<string, 'WineName'>
export type WineDomain = Brand<string, 'WineDomain'>
export type Appellation = Brand<string, 'Appellation'>
export type Classification = Brand<string, 'Classification'>
export type WineColor = 'red' | 'white' | 'rosé' | 'sparkling' | 'sweet'

export type WineSort = 'createdAt' | 'updatedAt' | 'vintage' | 'region' | 'color' | 'price'
export type SortOrder = 'asc' | 'desc'
export type WineStatus = 'in-cellar' | 'consumed' | 'gifted' | 'recommended'

export type Wine = {
  id: WineId
  userId: UserId
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
  notes?: string
  giftedBy?: PersonName
  servingTemperature?: number
  latitude?: Latitude
  longitude?: Longitude
  placeName?: PlaceName
  createdAt: Date
  updatedAt: Date
}
