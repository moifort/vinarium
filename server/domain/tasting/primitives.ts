import { make } from 'ts-brand'
import { z } from 'zod'
import type { Rating as RatingType } from '~/domain/tasting/types'

export const Rating = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().int().min(1).max(5))
    .parse(value)
  return make<RatingType>()(v)
}
