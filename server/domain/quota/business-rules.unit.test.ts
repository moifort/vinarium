import { describe, expect, it } from 'bun:test'
import {
  consumed,
  exhausted,
  FREE_MONTHLY_SCANS,
  freshQuota,
  limitOf,
  monthOf,
  PREMIUM_MONTHLY_SCANS,
  remaining,
  renewsOn,
} from '~/domain/quota/business-rules'
import { QuotaMonth } from '~/domain/quota/primitives'
import { Count, UserId } from '~/domain/shared/primitives'

const quotaOf = (scans: number) => ({
  ...freshQuota(UserId('u1'), QuotaMonth('2026-07')),
  scans: Count(scans),
})

describe('the month a scan counts against', () => {
  it('is the calendar month in UTC, so the window never moves with the caller', () => {
    expect(monthOf(new Date('2026-07-21T12:00:00.000Z')) as string).toBe('2026-07')
    expect(monthOf(new Date('2026-01-01T00:00:00.000Z')) as string).toBe('2026-01')
    expect(monthOf(new Date('2026-12-31T23:59:59.000Z')) as string).toBe('2026-12')
  })

  it('renews at midnight UTC on the 1st of the next month', () => {
    expect(renewsOn(QuotaMonth('2026-07'))).toEqual(new Date('2026-08-01T00:00:00.000Z'))
  })

  it('rolls December over into the next year', () => {
    expect(renewsOn(QuotaMonth('2026-12'))).toEqual(new Date('2027-01-01T00:00:00.000Z'))
  })
})

describe('what a plan allows in a month', () => {
  it('meters a free account', () => {
    expect(limitOf('free')).toBe(FREE_MONTHLY_SCANS)
  })

  it('leaves a subscriber a ceiling high enough never to meet it in normal use', () => {
    expect(limitOf('premium')).toBe(PREMIUM_MONTHLY_SCANS)
    expect(PREMIUM_MONTHLY_SCANS).toBeGreaterThan(FREE_MONTHLY_SCANS)
  })
})

describe('what is left this month', () => {
  it('starts at the full allowance', () => {
    expect(remaining('free', quotaOf(0))).toBe(FREE_MONTHLY_SCANS)
  })

  it('goes down with each scan spent', () => {
    expect(remaining('free', quotaOf(2))).toBe(Count(FREE_MONTHLY_SCANS - 2))
  })

  it('reads as zero rather than as a debt when the limit was lowered under the counter', () => {
    expect(remaining('free', quotaOf(FREE_MONTHLY_SCANS + 10))).toBe(Count(0))
  })
})

describe('whether the allowance is spent', () => {
  it('is not while a scan is left', () => {
    expect(exhausted('free', quotaOf(FREE_MONTHLY_SCANS - 1))).toBe(false)
  })

  it('is once the counter reaches the limit', () => {
    expect(exhausted('free', quotaOf(FREE_MONTHLY_SCANS))).toBe(true)
  })

  it('is not for a subscriber at the free limit', () => {
    expect(exhausted('premium', quotaOf(FREE_MONTHLY_SCANS))).toBe(false)
  })

  it('is for a subscriber past the abuse ceiling', () => {
    expect(exhausted('premium', quotaOf(PREMIUM_MONTHLY_SCANS))).toBe(true)
  })
})

describe('spending a scan', () => {
  it('adds one to the counter and leaves the rest alone', () => {
    expect(consumed(quotaOf(2))).toEqual({
      userId: UserId('u1'),
      month: QuotaMonth('2026-07'),
      scans: Count(3),
    })
  })
})
