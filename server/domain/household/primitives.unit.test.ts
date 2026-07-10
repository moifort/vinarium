import { describe, expect, test } from 'bun:test'
import { HouseholdId, InvitationCode, randomHouseholdId } from '~/domain/household/primitives'

describe('HouseholdId', () => {
  test('accepts a uuid', () => {
    const uuid = '3f2504e0-4f89-41d3-9a0c-0305e82c3301'
    expect(HouseholdId(uuid) as string).toBe(uuid)
  })
  test('rejects a non-uuid', () => expect(() => HouseholdId('nope')).toThrow())
  test('randomHouseholdId returns a valid uuid', () =>
    expect(() => HouseholdId(randomHouseholdId())).not.toThrow())
})

describe('InvitationCode', () => {
  test('accepts a valid code', () => expect(InvitationCode('ABC234') as string).toBe('ABC234'))
  test('upper-cases a lower-case code', () =>
    expect(InvitationCode('abc234') as string).toBe('ABC234'))
  test('trims surrounding whitespace', () =>
    expect(InvitationCode('  ABC234 ') as string).toBe('ABC234'))
  test('rejects the wrong length', () => expect(() => InvitationCode('ABC23')).toThrow())
  test('rejects ambiguous characters', () => {
    expect(() => InvitationCode('ABCDE0')).toThrow() // 0
    expect(() => InvitationCode('ABCDE1')).toThrow() // 1
    expect(() => InvitationCode('ABCDEO')).toThrow() // O
    expect(() => InvitationCode('ABCDEI')).toThrow() // I
  })
})
