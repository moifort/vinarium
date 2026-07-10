import { make } from 'ts-brand'
import { z } from 'zod'
import type {
  HouseholdId as HouseholdIdType,
  InvitationCode as InvitationCodeType,
} from '~/domain/household/types'

export const HouseholdId = (value: unknown) => {
  const v = z.string().uuid().parse(value)
  return make<HouseholdIdType>()(v)
}

export const randomHouseholdId = () => HouseholdId(crypto.randomUUID())

// Codes are drawn from an unambiguous alphabet (no O/0, I/1, etc.) so they survive
// being read aloud or copied by hand. Input is upper-cased before validation, so a
// lower-case paste still matches.
export const INVITATION_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
export const INVITATION_CODE_LENGTH = 6

export const InvitationCode = (value: unknown) => {
  const v = z
    .string()
    .transform((s) => s.trim().toUpperCase())
    .pipe(z.string().regex(/^[A-HJ-NP-Z2-9]{6}$/, 'Invalid invitation code'))
    .parse(value)
  return make<InvitationCodeType>()(v)
}
