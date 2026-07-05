import { describe, expect, test } from 'bun:test'
import {
  BEVERAGE_SUBTYPE_VALUES,
  BeverageSubtype,
  BeverageType,
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
    expect(WineId(uuid) as string).toBe(uuid)
  })
  test('rejects random string', () => expect(() => WineId('not-a-uuid')).toThrow())
})

describe('WineName', () => {
  test('accepts non-empty string', () => expect(WineName('Margaux') as string).toBe('Margaux'))
  test('rejects empty string', () => expect(() => WineName('')).toThrow())
})

describe('WineColor', () => {
  test.each(['red', 'white', 'rosé'] as const)('accepts "%s"', (color) =>
    expect(WineColor(color) as string).toBe(color))
  test('rejects invalid color', () => expect(() => WineColor('blue')).toThrow())
  test.each(['sparkling', 'sweet'] as const)('rejects legacy pseudo-color "%s"', (color) =>
    expect(() => WineColor(color)).toThrow())
})

describe('BeverageType', () => {
  test.each(['wine', 'spirit', 'beer', 'sake', 'cider', 'other'] as const)('accepts "%s"', (type) =>
    expect(BeverageType(type) as string).toBe(type))
  test('rejects invalid type', () => expect(() => BeverageType('juice')).toThrow())
})

describe('BeverageSubtype', () => {
  test('accepts every declared value', () => {
    for (const subtype of BEVERAGE_SUBTYPE_VALUES) {
      expect(BeverageSubtype(subtype) as string).toBe(subtype)
    }
  })
  test('rejects free text', () => expect(() => BeverageSubtype('Blonde forte')).toThrow())
  test('rejects empty string', () => expect(() => BeverageSubtype('')).toThrow())
})

describe('WineSort', () => {
  test.each([
    'createdAt',
    'updatedAt',
    'vintage',
    'region',
    'color',
    'price',
  ] as const)('accepts "%s"', (sort) => expect(WineSort(sort) as string).toBe(sort))
  test('rejects invalid sort', () => expect(() => WineSort('invalid')).toThrow())
})

describe('SortOrder', () => {
  test('accepts "asc"', () => expect(SortOrder('asc') as string).toBe('asc'))
  test('accepts "desc"', () => expect(SortOrder('desc') as string).toBe('desc'))
  test('rejects invalid order', () => expect(() => SortOrder('up')).toThrow())
})

describe('WineStatus', () => {
  test.each(['in-cellar', 'consumed', 'gifted', 'recommended'] as const)('accepts "%s"', (status) =>
    expect(WineStatus(status) as string).toBe(status))
  test('rejects invalid status', () => expect(() => WineStatus('invalid')).toThrow())
})
