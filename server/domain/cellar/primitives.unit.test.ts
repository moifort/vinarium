import { describe, expect, test } from 'bun:test'
import { make } from 'ts-brand'
import { CellarCol, CellarCols, CellarRow, CellarRows } from '~/domain/cellar/primitives'
import type { CellarCol as CellarColType, CellarRow as CellarRowType } from '~/domain/cellar/types'

describe('CellarRow', () => {
  test('accepts 0', () => expect(CellarRow(0)).toBe(0))
  test('coerces string to number', () => expect(CellarRow('0')).toBe(0))
  test('rejects negative', () => expect(() => CellarRow(-1)).toThrow())
})

describe('CellarRow.toLabel', () => {
  test('0 → "A"', () => expect(CellarRow.toLabel(make<CellarRowType>()(0))).toBe('A'))
  test('5 → "F"', () => expect(CellarRow.toLabel(make<CellarRowType>()(5))).toBe('F'))
})

describe('CellarCol', () => {
  test('accepts 0', () => expect(CellarCol(0)).toBe(0))
  test('coerces string to number', () => expect(CellarCol('0')).toBe(0))
  test('rejects negative', () => expect(() => CellarCol(-1)).toThrow())
})

describe('CellarCol.toLabel', () => {
  test('0 → 1', () => expect(CellarCol.toLabel(make<CellarColType>()(0))).toBe(1))
  test('7 → 8', () => expect(CellarCol.toLabel(make<CellarColType>()(7))).toBe(8))
})

describe('CellarRows', () => {
  test('accepts 1', () => expect(CellarRows(1)).toBe(1))
  test('accepts 100', () => expect(CellarRows(100)).toBe(100))
  test('rejects 0', () => expect(() => CellarRows(0)).toThrow())
  test('rejects 101', () => expect(() => CellarRows(101)).toThrow())
})

describe('CellarCols', () => {
  test('accepts 1', () => expect(CellarCols(1)).toBe(1))
  test('accepts 100', () => expect(CellarCols(100)).toBe(100))
  test('rejects 0', () => expect(() => CellarCols(0)).toThrow())
  test('rejects 101', () => expect(() => CellarCols(101)).toThrow())
})
