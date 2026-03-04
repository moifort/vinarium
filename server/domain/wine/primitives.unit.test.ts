import { describe, expect, test } from 'bun:test'
import {
  SortOrder,
  WineColor,
  WineId,
  WineName,
  WineSort,
  WineStatus,
} from '~/domain/wine/primitives'

describe('WineId', () => {
  test('accepts valid UUID', () => {
    const uuid = crypto.randomUUID()
    expect(WineId(uuid)).toBe(uuid)
  })
  test('rejects random string', () => expect(() => WineId('not-a-uuid')).toThrow())
})

describe('WineName', () => {
  test('accepts non-empty string', () => expect(WineName('Margaux')).toBe('Margaux'))
  test('rejects empty string', () => expect(() => WineName('')).toThrow())
})

describe('WineColor', () => {
  test.each(['red', 'white', 'rosé', 'sparkling', 'sweet'] as const)('accepts "%s"', (color) =>
    expect(WineColor(color)).toBe(color))
  test('rejects invalid color', () => expect(() => WineColor('blue')).toThrow())
})

describe('WineSort', () => {
  test.each([
    'createdAt',
    'updatedAt',
    'vintage',
    'region',
    'color',
    'price',
  ] as const)('accepts "%s"', (sort) => expect(WineSort(sort)).toBe(sort))
  test('rejects invalid sort', () => expect(() => WineSort('invalid')).toThrow())
})

describe('SortOrder', () => {
  test('accepts "asc"', () => expect(SortOrder('asc')).toBe('asc'))
  test('accepts "desc"', () => expect(SortOrder('desc')).toBe('desc'))
  test('rejects invalid order', () => expect(() => SortOrder('up')).toThrow())
})

describe('WineStatus', () => {
  test.each(['in-cellar', 'consumed', 'gifted', 'recommended'] as const)('accepts "%s"', (status) =>
    expect(WineStatus(status)).toBe(status))
  test('rejects invalid status', () => expect(() => WineStatus('invalid')).toThrow())
})
