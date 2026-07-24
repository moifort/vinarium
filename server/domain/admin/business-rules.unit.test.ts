import { describe, expect, test } from 'bun:test'
import { aiCostEur, freshUsage, monthOf, premiumBreakdown } from '~/domain/admin/business-rules'
import type { AiStepUsage, AiUsage } from '~/domain/admin/types'
import type { Entitlement, ProductId } from '~/domain/entitlement/types'
import type { Count, Month, UserId } from '~/domain/shared/types'

const month = '2026-07' as Month

const step = (promptTokens: number, outputTokens: number, thinkingTokens: number): AiStepUsage => ({
  promptTokens: promptTokens as Count,
  outputTokens: outputTokens as Count,
  thinkingTokens: thinkingTokens as Count,
})

const usage = (vision: AiStepUsage, enrichment: AiStepUsage): AiUsage => ({
  month,
  scans: 1 as Count,
  cacheHits: 0 as Count,
  vision,
  enrichment,
})

describe('pricing the month s AI consumption', () => {
  test('a month without a single scan costs nothing', () => {
    expect(aiCostEur(freshUsage(month)) as number).toBe(0)
  })

  test('input tokens bill at the input rate', () => {
    // 1M input tokens at $0.30/M and a 0.91 USD→EUR conversion.
    const cost = aiCostEur(usage(step(1_000_000, 0, 0), step(0, 0, 0)))
    expect(cost as number).toBeCloseTo(0.3 * 0.91, 10)
  })

  test('thinking tokens bill at the output rate, the point of tracking them apart', () => {
    const thinking = aiCostEur(usage(step(0, 0, 1_000_000), step(0, 0, 0)))
    const output = aiCostEur(usage(step(0, 1_000_000, 0), step(0, 0, 0)))
    expect(thinking as number).toBe(output as number)
    expect(thinking as number).toBeCloseTo(2.5 * 0.91, 10)
  })

  test('both steps add up', () => {
    const visionOnly = aiCostEur(usage(step(2600, 250, 1500), step(0, 0, 0)))
    const enrichmentOnly = aiCostEur(usage(step(0, 0, 0), step(5000, 200, 1500)))
    const both = aiCostEur(usage(step(2600, 250, 1500), step(5000, 200, 1500)))
    expect(both as number).toBeCloseTo((visionOnly as number) + (enrichmentOnly as number), 10)
  })

  test('a real scan lands around the documented ~0.01 EUR', () => {
    // The freemium doc's order of magnitude: ~2.6K in, ~250 out, ~1.5K thinking
    // for vision; ~5K in, ~200 out, ~1.5K thinking for enrichment.
    const cost = aiCostEur(usage(step(2600, 250, 1500), step(5000, 200, 1500)))
    expect(cost as number).toBeGreaterThan(0.005)
    expect(cost as number).toBeLessThan(0.02)
  })
})

describe('the month key', () => {
  test('is the UTC month, zero-padded', () => {
    expect(monthOf(new Date('2026-07-23T10:00:00.000Z')) as string).toBe('2026-07')
    expect(monthOf(new Date('2026-01-01T00:00:00.000Z')) as string).toBe('2026-01')
  })

  test('does not move with a timezone: the last hour of a UTC month still belongs to it', () => {
    expect(monthOf(new Date('2026-07-31T23:59:59.000Z')) as string).toBe('2026-07')
  })
})

describe('counting who is Premium', () => {
  const now = new Date('2026-07-23T00:00:00.000Z')

  const entitlement = (userId: string, productId: string, expiresAt: Date): Entitlement => ({
    userId: userId as UserId,
    productId: productId as ProductId,
    originalTransactionId: '2000000900000001' as Entitlement['originalTransactionId'],
    appAccountToken: 'bc4a0626-772c-4b01-a0ec-4d018ee55375' as Entitlement['appAccountToken'],
    expiresAt,
    updatedAt: now,
  })

  const future = new Date('2099-01-01T00:00:00.000Z')
  const past = new Date('2026-01-01T00:00:00.000Z')

  test('splits active subscribers by their billing period', () => {
    const breakdown = premiumBreakdown(
      [
        entitlement('u1', 'com.polyforms.vinarium.app.premium.yearly', future),
        entitlement('u2', 'com.polyforms.vinarium.app.premium.monthly', future),
        entitlement('u3', 'com.polyforms.vinarium.app.premium.yearly', future),
      ],
      now,
    )
    expect(breakdown.total as number).toBe(3)
    expect(breakdown.monthly as number).toBe(1)
    expect(breakdown.yearly as number).toBe(2)
  })

  test('an expired or revoked entitlement counts for nothing', () => {
    const revoked = {
      ...entitlement('u2', 'com.polyforms.vinarium.app.premium.monthly', future),
      revokedAt: past,
    }
    const breakdown = premiumBreakdown(
      [entitlement('u1', 'com.polyforms.vinarium.app.premium.yearly', past), revoked],
      now,
    )
    expect(breakdown.total as number).toBe(0)
  })

  test('an unexpected product id still counts in the total', () => {
    const breakdown = premiumBreakdown(
      [entitlement('u1', 'com.polyforms.vinarium.app.premium.lifetime', future)],
      now,
    )
    expect(breakdown.total as number).toBe(1)
    expect(breakdown.monthly as number).toBe(0)
    expect(breakdown.yearly as number).toBe(0)
  })

  test('nobody subscribed reads as zeros', () => {
    const breakdown = premiumBreakdown([], now)
    expect(breakdown).toEqual({
      total: 0 as Count,
      monthly: 0 as Count,
      yearly: 0 as Count,
    })
  })
})
