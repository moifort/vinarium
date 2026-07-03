import { make } from 'ts-brand'
import { z } from 'zod'
import type {
  Appellation as AppellationType,
  BeverageStyle as BeverageStyleType,
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
  z.enum(['red', 'white', 'rosé', 'sparkling', 'sweet']).parse(value) as WineColorType

export const BeverageType = (value: unknown) =>
  z.enum(['wine', 'spirit', 'beer', 'sake', 'cider', 'other']).parse(value) as BeverageTypeType

export const BeverageStyle = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<BeverageStyleType>()(v)
}

export const WineSort = (value: unknown) =>
  z
    .enum(['createdAt', 'updatedAt', 'vintage', 'region', 'color', 'price'])
    .parse(value) as WineSortType

export const SortOrder = (value: unknown) => z.enum(['asc', 'desc']).parse(value) as SortOrderType

export const WineStatus = (value: unknown) =>
  z.enum(['in-cellar', 'consumed', 'gifted', 'recommended']).parse(value) as WineStatusType
