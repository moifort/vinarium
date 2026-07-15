import { make } from 'ts-brand'
import { z } from 'zod'
import type {
  CellarColLabel as CellarColLabelType,
  CellarCols as CellarColsType,
  CellarCol as CellarColType,
  CellarRowLabel as CellarRowLabelType,
  CellarRows as CellarRowsType,
  CellarRow as CellarRowType,
  CellarZones as CellarZonesType,
} from '~/domain/cellar/types'

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

export const CellarZones = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().int().min(1).max(3))
    .parse(value)
  return make<CellarZonesType>()(v)
}

const cellarRow = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().int().min(0))
    .parse(value)
  return make<CellarRowType>()(v)
}

export const CellarRow = Object.assign(cellarRow, {
  toLabel: (row: CellarRowType) => make<CellarRowLabelType>()(String.fromCharCode(65 + row)),
})

const cellarCol = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().int().min(0))
    .parse(value)
  return make<CellarColType>()(v)
}

export const CellarCol = Object.assign(cellarCol, {
  toLabel: (col: CellarColType) => make<CellarColLabelType>()(col + 1),
})
