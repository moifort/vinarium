import { beforeEach, describe, expect, mock, test } from 'bun:test'
import { graphql } from 'graphql'
import type { ScanResult } from '~/domain/scan/types'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

// Nobody pays Google in a test: the scan is stubbed, and what is asserted is who
// is allowed to reach it and what reaching it costs the caller.
let cacheHit = false
let scanFails = false
const scanned = { calls: 0 }

const aScanResult = { recognized: true, name: 'Château Margaux', beverageType: 'wine' }

mock.module('~/domain/scan', () => ({
  Scan: {
    scanWithCache: async () => {
      scanned.calls += 1
      if (scanFails) throw new Error('Gemini is down')
      return { result: aScanResult as unknown as ScanResult, cacheHit }
    },
  },
}))

let compedUserIds: string[] = []
mock.module('~/system/config/index', () => ({
  config: () => ({ premiumUserIds: compedUserIds }),
}))

const { schema } = await import('~/domain/shared/graphql/schema')
const { beverageSatelliteLoaders } = await import('~/domain/shared/graphql/loaders')
const { FREE_MONTHLY_SCANS } = await import('~/domain/quota/business-rules')
const { QuotaCommand } = await import('~/domain/quota/command')
const { EntitlementQuery } = await import('~/domain/entitlement/query')

const userId = 'user-1' as UserId

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
  cacheHit = false
  scanFails = false
  scanned.calls = 0
  compedUserIds = []
})

const execute = (source: string) =>
  graphql({
    schema,
    source,
    contextValue: { userId, event: undefined as never, loaders: beverageSatelliteLoaders(userId) },
  })

const scan = () => execute(`mutation { scanBeverage(imageBase64: "aGVsbG8=") { name recognized } }`)

const errorCodeOf = (result: Awaited<ReturnType<typeof execute>>) =>
  result.errors?.[0]?.extensions?.code

// Spend the whole free allowance the way a real month would.
const spendFreeAllowance = async () => {
  for (let i = 0; i < FREE_MONTHLY_SCANS; i++) await QuotaCommand.record(userId)
}

// Make this account Premium the way a verified purchase does.
const subscribe = async (expiresAt = new Date('2099-01-01T00:00:00.000Z')) => {
  fake.seed('entitlements', userId, {
    userId,
    productId: 'com.polyforms.vinarium.app.premium.yearly',
    originalTransactionId: '2000000900000001',
    appAccountToken: EntitlementQuery.tokenFor(userId) as string,
    expiresAt,
    updatedAt: new Date('2026-07-21T00:00:00.000Z'),
  })
}

describe('scanning within the free allowance', () => {
  test('returns the label and spends one scan', async () => {
    const result = await scan()

    expect(result.errors).toBeUndefined()
    expect(result.data?.scanBeverage).toMatchObject({ name: 'Château Margaux' })

    const quota = await execute(`query { quota { used remaining limit plan } }`)
    expect(quota.data?.quota).toMatchObject({
      used: 1,
      remaining: FREE_MONTHLY_SCANS - 1,
      limit: FREE_MONTHLY_SCANS,
      plan: 'FREE',
    })
  })

  test('lets the last scan of the allowance through', async () => {
    for (let i = 0; i < FREE_MONTHLY_SCANS - 1; i++) await QuotaCommand.record(userId)

    expect((await scan()).errors).toBeUndefined()
  })
})

describe('scanning once the free allowance is spent', () => {
  test('is refused with QUOTA_EXHAUSTED', async () => {
    await spendFreeAllowance()

    const result = await scan()

    expect(errorCodeOf(result)).toBe('QUOTA_EXHAUSTED')
  })

  test('never reaches the model, so it costs nothing to refuse', async () => {
    await spendFreeAllowance()

    await scan()

    expect(scanned.calls).toBe(0)
  })
})

describe('scanning as a subscriber', () => {
  test('goes through well past the free allowance', async () => {
    await subscribe()
    await spendFreeAllowance()

    const result = await scan()

    expect(result.errors).toBeUndefined()
    expect((await execute(`query { quota { plan } }`)).data?.quota).toMatchObject({
      plan: 'PREMIUM',
    })
  })

  test('falls back to the free allowance once the subscription has expired', async () => {
    await subscribe(new Date('2026-01-01T00:00:00.000Z'))
    await spendFreeAllowance()

    expect(errorCodeOf(await scan())).toBe('QUOTA_EXHAUSTED')
  })

  test('goes through for a comped account, which never bought anything', async () => {
    compedUserIds = [userId]
    await spendFreeAllowance()

    expect((await scan()).errors).toBeUndefined()
  })
})

describe('what a scan actually costs the caller', () => {
  test('a cached label spends nothing', async () => {
    cacheHit = true

    await scan()

    expect((await execute(`query { quota { used } }`)).data?.quota).toMatchObject({ used: 0 })
  })

  test('a failed model call spends nothing', async () => {
    scanFails = true

    const result = await scan()

    expect(errorCodeOf(result)).toBe('SCAN_FAILED')
    expect((await execute(`query { quota { used } }`)).data?.quota).toMatchObject({ used: 0 })
  })

  test('an oversized image is refused before the quota is even read', async () => {
    const tooBig = 'a'.repeat(14 * 1024 * 1024)
    const result = await execute(`mutation { scanBeverage(imageBase64: "${tooBig}") { name } }`)

    expect(errorCodeOf(result)).toBe('IMAGE_TOO_LARGE')
    expect(scanned.calls).toBe(0)
  })
})

describe('the reads a gated scan pays for', () => {
  // The plan and the month's counter, then the counter again inside the
  // transaction that spends it — that last one is the price of counting two
  // scans that land together as two. All keyed reads: gating a scan must never
  // scan a collection.
  test('costs three keyed document reads and no collection scan', async () => {
    await scan()

    expect(fake.docReads).toBe(3)
    expect(fake.queryReads).toBe(0)
  })

  test('refusing a scan costs only the two gate reads', async () => {
    await spendFreeAllowance()
    const before = fake.docReads

    await scan()

    expect(fake.docReads - before).toBe(2)
  })
})
