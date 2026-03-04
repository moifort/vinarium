import { describe, expect, test } from 'bun:test'
import { Country, Eur, Month, PersonName, Region, Year } from '~/domain/shared/primitives'

describe('Eur', () => {
  test('accepts 0', () => expect(Eur(0)).toBe(0))
  test('accepts positive number', () => expect(Eur(15.5)).toBe(15.5))
  test('coerces string to number', () => expect(Eur('10')).toBe(10))
  test('rejects negative', () => expect(() => Eur(-1)).toThrow())
  test('rejects non-numeric string', () => expect(() => Eur('abc')).toThrow())
})

describe('Year', () => {
  test('accepts valid year', () => expect(Year(2024)).toBe(2024))
  test('coerces string to number', () => expect(Year('2024')).toBe(2024))
  test('accepts minimum year 1800', () => expect(Year(1800)).toBe(1800))
  test('rejects below 1800', () => expect(() => Year(1799)).toThrow())
  test('rejects non-integer', () => expect(() => Year(2024.5)).toThrow())
})

describe('Country', () => {
  test('accepts non-empty string', () => expect(Country('France')).toBe('France'))
  test('rejects empty string', () => expect(() => Country('')).toThrow())
})

describe('Region', () => {
  test('accepts non-empty string', () => expect(Region('Bordeaux')).toBe('Bordeaux'))
  test('rejects empty string', () => expect(() => Region('')).toThrow())
})

describe('Month', () => {
  test('accepts YYYY-MM format', () => expect(Month('2024-01')).toBe('2024-01'))
  test('rejects YYYY format', () => expect(() => Month('2024')).toThrow())
  test('rejects YYYY/MM format', () => expect(() => Month('2024/01')).toThrow())
})

describe('PersonName', () => {
  test('accepts valid name', () => expect(PersonName('Jean')).toBe('Jean'))
  test('accepts 200 chars', () => expect(PersonName('a'.repeat(200))).toBe('a'.repeat(200)))
  test('rejects empty string', () => expect(() => PersonName('')).toThrow())
  test('rejects over 200 chars', () => expect(() => PersonName('a'.repeat(201))).toThrow())
})
