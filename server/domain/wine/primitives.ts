import { make } from 'ts-brand'
import { z } from 'zod'
import type {
  Appellation as AppellationType,
  BeverageSubtype as BeverageSubtypeType,
  BeverageType as BeverageTypeType,
  Classification as ClassificationType,
  SortOrder as SortOrderType,
  WineColor as WineColorType,
  WineDomain as WineDomainType,
  WineId as WineIdType,
  WineName as WineNameType,
  WineSort as WineSortType,
  WineStatus as WineStatusType,
} from '~/domain/wine/types'

export const WineId = (value: unknown) => {
  const v = z.string().uuid().parse(value)
  return make<WineIdType>()(v)
}

export const randomWineId = () => WineId(crypto.randomUUID())

export const WineName = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<WineNameType>()(v)
}

export const WineDomain = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<WineDomainType>()(v)
}

export const Appellation = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<AppellationType>()(v)
}

export const Classification = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<ClassificationType>()(v)
}

export const WineColor = (value: unknown) =>
  z.enum(['red', 'white', 'rosé']).parse(value) as WineColorType

export const BeverageType = (value: unknown) =>
  z.enum(['wine', 'spirit', 'beer', 'sake', 'cider', 'other']).parse(value) as BeverageTypeType

// Single source for the Zod enums (scan schema reuses it). Must stay in sync
// with the BeverageSubtype union in types.ts and SUBTYPES_BY_BEVERAGE.
export const BEVERAGE_SUBTYPE_VALUES = [
  'sparkling',
  'sweet',
  'late-harvest',
  'vin-jaune',
  'porto',
  'fortified',
  'rum',
  'whisky',
  'gin',
  'vodka',
  'cognac',
  'armagnac',
  'tequila',
  'liqueur',
  'eau-de-vie',
  'blonde',
  'blanche',
  'amber',
  'brune',
  'ipa',
  'stout',
  'pils',
  'triple',
  'junmai',
  'ginjo',
  'daiginjo',
  'honjozo',
  'nigori',
  'brut',
  'doux',
  'demi-sec',
  'poire',
  'other',
] as const

export const BeverageSubtype = (value: unknown) =>
  z.enum(BEVERAGE_SUBTYPE_VALUES).parse(value) as BeverageSubtypeType

export const WineSort = (value: unknown) =>
  z
    .enum(['createdAt', 'updatedAt', 'vintage', 'region', 'color', 'price'])
    .parse(value) as WineSortType

export const SortOrder = (value: unknown) => z.enum(['asc', 'desc']).parse(value) as SortOrderType

export const WineStatus = (value: unknown) =>
  z.enum(['in-cellar', 'consumed', 'gifted', 'recommended']).parse(value) as WineStatusType
