import type { Brand } from 'ts-brand'
import type {
  Country,
  Eur,
  Latitude,
  Longitude,
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

// The years a wine is at its best — either bound may stand alone (a wine to
// drink "from 2028" with no upper bound, or "before 2030" with no lower one).
export type DrinkWindow = { from?: Year; until?: Year }

// Where the bottle was bought. A coordinate pair always travels together; the
// place name may exist without them (a shop typed by hand) and vice-versa.
export type WinePlace = { latitude?: Latitude; longitude?: Longitude; name?: PlaceName }

// What the bottle cost and when it was acquired.
export type WinePurchase = { price?: Eur; date?: string }

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
  purchase?: WinePurchase
  drinkWindow?: DrinkWindow
  notes?: string
  servingTemperature?: number
  place?: WinePlace
  createdAt: Date
  updatedAt: Date
}
