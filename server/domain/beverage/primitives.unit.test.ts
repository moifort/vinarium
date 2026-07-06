import { describe, expect, test } from 'bun:test'
import {
  BEVERAGE_SUBTYPE_VALUES,
  BeverageId,
  BeverageName,
  BeverageSort,
  BeverageStatus,
  BeverageSubtype,
  BeverageType,
  SortOrder,
  WineColor,
} from '~/domain/beverage/primitives'

describe('BeverageId', () => {
  test('accepts valid UUID', () => {
    const uuid = crypto.randomUUID()
    expect(BeverageId(uuid) as string).toBe(uuid)
  })
  test('rejects random string', () => expect(() => BeverageId('not-a-uuid')).toThrow())
})

describe('BeverageName', () => {
  test('accepts non-empty string', () => expect(BeverageName('Margaux') as string).toBe('Margaux'))
  test('rejects empty string', () => expect(() => BeverageName('')).toThrow())
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

describe('BeverageSort', () => {
  test.each([
    'createdAt',
    'updatedAt',
    'vintage',
    'region',
    'color',
    'price',
  ] as const)('accepts "%s"', (sort) => expect(BeverageSort(sort) as string).toBe(sort))
  test('rejects invalid sort', () => expect(() => BeverageSort('invalid')).toThrow())
})

describe('SortOrder', () => {
  test('accepts "asc"', () => expect(SortOrder('asc') as string).toBe('asc'))
  test('accepts "desc"', () => expect(SortOrder('desc') as string).toBe('desc'))
  test('rejects invalid order', () => expect(() => SortOrder('up')).toThrow())
})

describe('BeverageStatus', () => {
  test.each(['in-cellar', 'consumed', 'gifted', 'recommended'] as const)('accepts "%s"', (status) =>
    expect(BeverageStatus(status) as string).toBe(status))
  test('rejects invalid status', () => expect(() => BeverageStatus('invalid')).toThrow())
})
