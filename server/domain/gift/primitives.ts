import { make } from 'ts-brand'
import { z } from 'zod'
import type { RecipientName as RecipientNameType } from '~/domain/gift/types'

export const RecipientName = (value: unknown) => {
  const validatedValue = z.string().min(1).max(200).parse(value)
  return make<RecipientNameType>()(validatedValue)
}
