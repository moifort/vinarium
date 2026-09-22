import { make } from 'ts-brand'
import { z } from 'zod'
import type { JournalEntryId as JournalEntryIdType } from '~/domain/journal/types'

// A Firestore document id: never empty, never a path.
export const JournalEntryId = (value: unknown) => {
  const v = z
    .string()
    .min(1)
    .max(128)
    .refine((id) => !id.includes('/'))
    .parse(value)
  return make<JournalEntryIdType>()(v)
}
