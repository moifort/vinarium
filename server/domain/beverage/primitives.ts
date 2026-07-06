import { make } from 'ts-brand'
import { z } from 'zod'
import type {
  Appellation as AppellationType,
  BeverageId as BeverageIdType,
  BeverageName as BeverageNameType,
  BeverageSort as BeverageSortType,
  BeverageStatus as BeverageStatusType,
  BeverageSubtype as BeverageSubtypeType,
  BeverageType as BeverageTypeType,
  Celsius as CelsiusType,
  Classification as ClassificationType,
  GrapeVariety as GrapeVarietyType,
  Notes as NotesType,
  Producer as ProducerType,
  SortOrder as SortOrderType,
  WineColor as WineColorType,
} from '~/domain/beverage/types'

export const BeverageId = (value: unknown) => {
  const v = z.string().uuid().parse(value)
  return make<BeverageIdType>()(v)
}

export const randomBeverageId = () => BeverageId(crypto.randomUUID())

export const BeverageName = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<BeverageNameType>()(v)
}

export const Producer = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<ProducerType>()(v)
}

export const Notes = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<NotesType>()(v)
}

export const Appellation = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<AppellationType>()(v)
}

export const Classification = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<ClassificationType>()(v)
}

export const GrapeVariety = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<GrapeVarietyType>()(v)
}

export const Celsius = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().min(-50).max(100))
    .parse(value)
  return make<CelsiusType>()(v)
}

export const WineColor = (value: unknown) =>
  z.enum(['red', 'white', 'rosé']).parse(value) as WineColorType

export const BeverageType = (value: unknown) =>
  z.enum(['wine', 'spirit', 'beer', 'sake', 'cider', 'other']).parse(value) as BeverageTypeType

// Per-type subtype sets — the single source of truth. The Zod enums below and
// SUBTYPES_BY_BEVERAGE (business-rules) both derive from these, and the flat
// aggregate (reused by the scan schema) is their deduplicated union.
export const WINE_SUBTYPES = [
  'sparkling',
  'sweet',
  'late-harvest',
  'vin-jaune',
  'porto',
  'fortified',
  'other',
] as const
export const SPIRIT_SUBTYPES = [
  'rum',
  'whisky',
  'gin',
  'vodka',
  'cognac',
  'armagnac',
  'tequila',
  'liqueur',
  'eau-de-vie',
  'other',
] as const
export const BEER_SUBTYPES = [
  'blonde',
  'blanche',
  'amber',
  'brune',
  'ipa',
  'stout',
  'pils',
  'triple',
  'other',
] as const
export const SAKE_SUBTYPES = [
  'junmai',
  'ginjo',
  'daiginjo',
  'honjozo',
  'nigori',
  'sparkling',
  'other',
] as const
export const CIDER_SUBTYPES = ['brut', 'doux', 'demi-sec', 'poire', 'other'] as const
export const OTHER_SUBTYPES = ['other'] as const

export const WineSubtype = (value: unknown) => z.enum(WINE_SUBTYPES).parse(value)
export const SpiritSubtype = (value: unknown) => z.enum(SPIRIT_SUBTYPES).parse(value)
export const BeerSubtype = (value: unknown) => z.enum(BEER_SUBTYPES).parse(value)
export const SakeSubtype = (value: unknown) => z.enum(SAKE_SUBTYPES).parse(value)
export const CiderSubtype = (value: unknown) => z.enum(CIDER_SUBTYPES).parse(value)

// Flat aggregate of every subtype (deduplicated) — the scan schema reuses it.
export const BEVERAGE_SUBTYPE_VALUES = [
  ...WINE_SUBTYPES,
  ...SPIRIT_SUBTYPES,
  ...BEER_SUBTYPES,
  ...SAKE_SUBTYPES,
  ...CIDER_SUBTYPES,
].filter((value, index, all) => all.indexOf(value) === index) as [
  BeverageSubtypeType,
  ...BeverageSubtypeType[],
]

export const BeverageSubtype = (value: unknown) =>
  z.enum(BEVERAGE_SUBTYPE_VALUES).parse(value) as BeverageSubtypeType

export const BeverageSort = (value: unknown) =>
  z
    .enum(['createdAt', 'updatedAt', 'vintage', 'region', 'color', 'price'])
    .parse(value) as BeverageSortType

export const SortOrder = (value: unknown) => z.enum(['asc', 'desc']).parse(value) as SortOrderType

export const BeverageStatus = (value: unknown) =>
  z.enum(['in-cellar', 'consumed', 'gifted', 'recommended']).parse(value) as BeverageStatusType
