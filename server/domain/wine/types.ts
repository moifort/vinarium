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
export type WineColor = 'red' | 'white' | 'rosé'
export type BeverageType = 'wine' | 'spirit' | 'beer' | 'sake' | 'cider' | 'other'
// Structured refinement of a beverageType. One flat enum for every type: which
// values a given type accepts is a business rule (SUBTYPES_BY_BEVERAGE), not a
// schema constraint. 'sparkling' is shared by wine and sake; 'other' fits all.
export type BeverageSubtype =
  // wine
  | 'sparkling'
  | 'sweet'
  | 'late-harvest'
  | 'vin-jaune'
  | 'porto'
  | 'fortified'
  // spirit
  | 'rum'
  | 'whisky'
  | 'gin'
  | 'vodka'
  | 'cognac'
  | 'armagnac'
  | 'tequila'
  | 'liqueur'
  | 'eau-de-vie'
  // beer
  | 'blonde'
  | 'blanche'
  | 'amber'
  | 'brune'
  | 'ipa'
  | 'stout'
  | 'pils'
  | 'triple'
  // sake
  | 'junmai'
  | 'ginjo'
  | 'daiginjo'
  | 'honjozo'
  | 'nigori'
  // cider
  | 'brut'
  | 'doux'
  | 'demi-sec'
  | 'poire'
  // any type
  | 'other'

export type WineSort = 'createdAt' | 'updatedAt' | 'vintage' | 'region' | 'color' | 'price'
export type SortOrder = 'asc' | 'desc'
export type WineStatus = 'in-cellar' | 'consumed' | 'gifted' | 'recommended'
// Which view of the wine list is shown, and an optional lifecycle filter on it.
export type WineListMode = 'all' | 'favorites' | 'gifted' | 'recommended'
export type WineStatusFilter = 'all' | 'in-cellar' | 'consumed'

export type Wine = {
  id: WineId
  userId: UserId
  name: WineName
  beverageType: BeverageType
  color?: WineColor
  subtype?: BeverageSubtype
  alcoholContent?: number
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
