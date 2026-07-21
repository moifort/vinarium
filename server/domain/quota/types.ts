import type { Brand } from 'ts-brand'
import type { Count, UserId } from '~/domain/shared/types'

/** The calendar month a quota counts for, `"2026-07"`. The window IS the month:
 *  the counter never resets, the next month simply gets its own document. */
export type QuotaMonth = Brand<string, 'QuotaMonth'>

/** One account's AI consumption for one month. Absent storage means a fresh
 *  month, which reads back as a counter at zero (see the repository).
 *
 *  A scan is the app's only variable cost, so it is the only thing counted. */
export type Quota = {
  userId: UserId
  month: QuotaMonth
  scans: Count
}
