import { describe, expect, test } from 'bun:test'
import { Rating } from '~/domain/tasting/primitives'

describe('Rating', () => {
  test('accepts 1', () => expect(Rating(1) as number).toBe(1))
  test('accepts 5', () => expect(Rating(5) as number).toBe(5))
  test('coerces string to number', () => expect(Rating('3') as number).toBe(3))
  test('rejects 0', () => expect(() => Rating(0)).toThrow())
  test('rejects 6', () => expect(() => Rating(6)).toThrow())
})
