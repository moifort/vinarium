import { make } from 'ts-brand'
import { z } from 'zod'
import type {
  CellarCols as CellarColsType,
  CellarCol as CellarColType,
  CellarRows as CellarRowsType,
  CellarRow as CellarRowType,
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

const cellarRow = (value: unknown) => {
  const v = z
    .string()
    .regex(/^[A-Z]$/)
    .parse(value)
  return make<CellarRowType>()(v)
}

export const CellarRow = Object.assign(cellarRow, {
  fromIndex: (index: number) => cellarRow(String.fromCharCode(65 + index)),
  toIndex: (row: CellarRowType) => row.charCodeAt(0) - 65,
})

const cellarCol = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().int().min(1).max(100))
    .parse(value)
  return make<CellarColType>()(v)
}

export const CellarCol = Object.assign(cellarCol, {
  fromIndex: (index: number) => cellarCol(index + 1),
  toIndex: (col: CellarColType) => col - 1,
})
