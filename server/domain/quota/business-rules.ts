import { QuotaMonth as toQuotaMonth } from '~/domain/quota/primitives'
import type { Quota, QuotaMonth } from '~/domain/quota/types'
import { Count } from '~/domain/shared/primitives'
import type { Count as CountType, Plan, UserId } from '~/domain/shared/types'

// What a free account gets each calendar month. The AI scan is the app's only
// variable cost, so this one number is the whole free tier: bottles, cellar,
// tastings and sharing stay unlimited, and a bottle can always be added by hand.
// Single source of truth — the GraphQL surface and the gate both read it here.
export const FREE_MONTHLY_SCANS: CountType = Count(5)

// A subscriber is not metered, but no single account may cost more than it pays:
// past this, a month's scans are refused as abuse rather than served at a loss.
// High enough that stocking a whole cellar in one sitting never reaches it.
export const PREMIUM_MONTHLY_SCANS: CountType = Count(200)

// The month a moment belongs to, `"2026-07"`. UTC on purpose: the window must not
// move with the caller's timezone, and someone scanning near midnight on the 1st
// is a rounding question nobody will ever ask.
export const monthOf = (moment: Date): QuotaMonth =>
  toQuotaMonth(`${moment.getUTCFullYear()}-${String(moment.getUTCMonth() + 1).padStart(2, '0')}`)

// When the counter goes back to zero: midnight UTC on the 1st of the next month.
// `Date.UTC` rolls December over to January on its own.
export const renewsOn = (month: QuotaMonth): Date => {
  const [year, index] = (month as string).split('-').map(Number)
  return new Date(Date.UTC(year as number, index as number, 1))
}

// A month nobody has spent anything in yet — what an absent document means.
export const freshQuota = (userId: UserId, month: QuotaMonth): Quota => ({
  userId,
  month,
  scans: Count(0),
})

// How many scans the plan allows per month.
export const limitOf = (plan: Plan): CountType =>
  plan === 'premium' ? PREMIUM_MONTHLY_SCANS : FREE_MONTHLY_SCANS

// What is left this month. Never negative: a limit lowered under an already-spent
// counter reads as zero, not as a debt.
export const remaining = (plan: Plan, quota: Quota): CountType =>
  Count(Math.max(0, limitOf(plan) - quota.scans))

export const exhausted = (plan: Plan, quota: Quota): boolean => quota.scans >= limitOf(plan)

// The quota once a scan has been spent.
export const consumed = (quota: Quota): Quota => ({ ...quota, scans: Count(quota.scans + 1) })
