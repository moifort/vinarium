import { describe, expect, test } from 'bun:test'
import {
  Country,
  Eur,
  Latitude,
  Longitude,
  Month,
  PersonName,
  PlaceName,
  Region,
  Year,
} from '~/domain/shared/primitives'

describe('Eur', () => {
  test('accepts 0', () => expect(Eur(0) as number).toBe(0))
  test('accepts positive number', () => expect(Eur(15.5) as number).toBe(15.5))
  test('coerces string to number', () => expect(Eur('10') as number).toBe(10))
  test('rejects negative', () => expect(() => Eur(-1)).toThrow())
  test('rejects non-numeric string', () => expect(() => Eur('abc')).toThrow())
})

describe('Latitude', () => {
  test('accepts valid latitude', () => expect(Latitude(44.84) as number).toBe(44.84))
  test('coerces string to number', () => expect(Latitude('44.84') as number).toBe(44.84))
  test('accepts boundary -90', () => expect(Latitude(-90) as number).toBe(-90))
  test('accepts boundary 90', () => expect(Latitude(90) as number).toBe(90))
  test('rejects below -90', () => expect(() => Latitude(-90.1)).toThrow())
  test('rejects above 90', () => expect(() => Latitude(90.1)).toThrow())
  test('rejects non-numeric string', () => expect(() => Latitude('abc')).toThrow())
})

describe('Longitude', () => {
  test('accepts valid longitude', () => expect(Longitude(-0.58) as number).toBe(-0.58))
  test('coerces string to number', () => expect(Longitude('-0.58') as number).toBe(-0.58))
  test('accepts boundary -180', () => expect(Longitude(-180) as number).toBe(-180))
  test('accepts boundary 180', () => expect(Longitude(180) as number).toBe(180))
  test('rejects below -180', () => expect(() => Longitude(-180.1)).toThrow())
  test('rejects above 180', () => expect(() => Longitude(180.1)).toThrow())
})

describe('PlaceName', () => {
  test('accepts non-empty string', () =>
    expect(PlaceName('Bordeaux, France') as string).toBe('Bordeaux, France'))
  test('accepts 200 chars', () =>
    expect(PlaceName('a'.repeat(200)) as string).toBe('a'.repeat(200)))
  test('rejects empty string', () => expect(() => PlaceName('')).toThrow())
  test('rejects over 200 chars', () => expect(() => PlaceName('a'.repeat(201))).toThrow())
})

describe('Year', () => {
  test('accepts valid year', () => expect(Year(2024) as number).toBe(2024))
  test('coerces string to number', () => expect(Year('2024') as number).toBe(2024))
  test('accepts minimum year 1800', () => expect(Year(1800) as number).toBe(1800))
  test('rejects below 1800', () => expect(() => Year(1799)).toThrow())
  test('rejects non-integer', () => expect(() => Year(2024.5)).toThrow())
})

describe('Country', () => {
  test('accepts non-empty string', () => expect(Country('France') as string).toBe('France'))
  test('rejects empty string', () => expect(() => Country('')).toThrow())
})

describe('Region', () => {
  test('accepts non-empty string', () => expect(Region('Bordeaux') as string).toBe('Bordeaux'))
  test('rejects empty string', () => expect(() => Region('')).toThrow())
})

describe('Month', () => {
  test('accepts YYYY-MM format', () => expect(Month('2024-01') as string).toBe('2024-01'))
  test('rejects YYYY format', () => expect(() => Month('2024')).toThrow())
  test('rejects YYYY/MM format', () => expect(() => Month('2024/01')).toThrow())
})

describe('PersonName', () => {
  test('accepts valid name', () => expect(PersonName('Jean') as string).toBe('Jean'))
  test('accepts 200 chars', () =>
    expect(PersonName('a'.repeat(200)) as string).toBe('a'.repeat(200)))
  test('rejects empty string', () => expect(() => PersonName('')).toThrow())
  test('rejects over 200 chars', () => expect(() => PersonName('a'.repeat(201))).toThrow())
})
