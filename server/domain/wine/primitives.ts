import { make } from 'ts-brand'
import { z } from 'zod'
import type {
  Appellation as AppellationType,
  Classification as ClassificationType,
  WineDomain as WineDomainType,
  WineId as WineIdType,
  WineName as WineNameType,
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
