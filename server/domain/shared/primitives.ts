import { make } from 'ts-brand'
import { z } from 'zod'
import type {
  Country as CountryType,
  Count as CountType,
  Eur as EurType,
  Latitude as LatitudeType,
  Longitude as LongitudeType,
  Month as MonthType,
  Percentage as PercentageType,
  PersonName as PersonNameType,
  PlaceName as PlaceNameType,
  Region as RegionType,
  UserId as UserIdType,
  Year as YearType,
} from '~/domain/shared/types'

export const UserId = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<UserIdType>()(v)
}

export const Eur = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().nonnegative())
    .parse(value)
  return make<EurType>()(v)
}

export const Latitude = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().min(-90).max(90))
    .parse(value)
  return make<LatitudeType>()(v)
}

export const Longitude = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().min(-180).max(180))
    .parse(value)
  return make<LongitudeType>()(v)
}

export const PlaceName = (value: unknown) => {
  const v = z.string().min(1).max(200).parse(value)
  return make<PlaceNameType>()(v)
}

export const Year = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().int().min(1800))
    .parse(value)
  return make<YearType>()(v)
}

export const Country = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<CountryType>()(v)
}

export const Region = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<RegionType>()(v)
}

export const Month = (value: unknown) => {
  const v = z
    .string()
    .regex(/^\d{4}-\d{2}$/)
    .parse(value)
  return make<MonthType>()(v)
}

export const Count = (value: number) => make<CountType>()(value)

export const Percentage = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().min(0).max(100))
    .parse(value)
  return make<PercentageType>()(v)
}

export const PersonName = (value: unknown) => {
  const v = z.string().min(1).max(200).parse(value)
  return make<PersonNameType>()(v)
}
