import { make } from 'ts-brand'
import { z } from 'zod'
import type {
  AlcoholContent as AlcoholContentType,
  WineId as WineIdType,
  WineName as WineNameType,
} from '~/wine/types'

export const WineId = (value: unknown) => {
  const v = z.string().uuid().parse(value)
  return make<WineIdType>()(v)
}

export const randomWineId = () => WineId(crypto.randomUUID())

export const WineName = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<WineNameType>()(v)
}

export const AlcoholContent = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().min(0).max(25))
    .parse(value)
  return make<AlcoholContentType>()(v)
}
