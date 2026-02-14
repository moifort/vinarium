import { make } from 'ts-brand'
import { z } from 'zod'
import type {
  CellarCols as CellarColsType,
  CellarCol as CellarColType,
  CellarRows as CellarRowsType,
  CellarRow as CellarRowType,
  Rating as RatingType,
} from '~/cellar/types'

export const CellarRows = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().int().min(1).max(100))
    .parse(value)
  return make<CellarRowsType>()(v)
}

export const CellarCols = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().int().min(1).max(100))
    .parse(value)
  return make<CellarColsType>()(v)
}

export const CellarRow = (value: unknown) => {
  const v = z
    .string()
    .regex(/^[A-Z]$/)
    .parse(value)
  return make<CellarRowType>()(v)
}

export const CellarCol = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().int().min(1).max(100))
    .parse(value)
  return make<CellarColType>()(v)
}

export const Rating = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().int().min(1).max(5))
    .parse(value)
  return make<RatingType>()(v)
}

export const rowToIndex = (row: CellarRowType) => row.charCodeAt(0) - 65
export const indexToRow = (index: number) => CellarRow(String.fromCharCode(65 + index))
export const colToIndex = (col: CellarColType) => col - 1
export const indexToCol = (index: number) => CellarCol(index + 1)
