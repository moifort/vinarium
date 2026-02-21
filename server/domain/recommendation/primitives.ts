import { make } from 'ts-brand'
import { z } from 'zod'
import type { RecommenderName as RecommenderNameType } from '~/domain/recommendation/types'

export const RecommenderName = (value: unknown) => {
  const validatedValue = z.string().min(1).max(200).parse(value)
  return make<RecommenderNameType>()(validatedValue)
}
