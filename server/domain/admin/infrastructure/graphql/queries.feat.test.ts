import { beforeEach, describe, expect, mock, test } from 'bun:test'
import { graphql } from 'graphql'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { schema } = await import('~/domain/shared/graphql/schema')
const { beverageSatelliteLoaders } = await import('~/domain/shared/graphql/loaders')

const userId = 'user-1' as UserId

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
})

const execute = (source: string) =>
  graphql({
    schema,
    source,
    contextValue: { userId, event: undefined as never, loaders: beverageSatelliteLoaders(userId) },
  })

const seedProfile = (admin: boolean) => {
  fake.seed('user-profiles', userId, {
    userId,
    firstName: 'Thibaut',
    onboardingCompletedAt: new Date('2026-07-01T00:00:00.000Z'),
    ...(admin ? { admin: true } : {}),
  })
}

const metricsQuery = `query {
  adminMetrics {
    aiCostEur
    infraEur
    totalCostEur
    totalUsers
    premiumTotal
    revenueProceedsEur
    scans
    cacheHits
    vision { promptTokens thinkingTokens }
    refreshedAt
  }
}`

describe('who may read the admin metrics', () => {
  test('an ordinary account is refused with FORBIDDEN', async () => {
    seedProfile(false)

    const result = await execute(metricsQuery)

    expect(result.errors?.[0]?.extensions?.code).toBe('FORBIDDEN')
    expect(result.data).toBeNull()
  })

  test('an account without any profile is refused too', async () => {
    const result = await execute(metricsQuery)

    expect(result.errors?.[0]?.extensions?.code).toBe('FORBIDDEN')
  })

  test('an admin account gets the payload', async () => {
    seedProfile(true)

    const result = await execute(metricsQuery)

    expect(result.errors).toBeUndefined()
    expect(result.data?.adminMetrics).toMatchObject({
      totalUsers: 0,
      premiumTotal: 0,
      revenueProceedsEur: null,
      refreshedAt: null,
    })
  })
})

describe('what the admin flag says on me', () => {
  test('is false for an ordinary account and true for an admin', async () => {
    seedProfile(false)
    expect((await execute(`query { me { isAdmin } }`)).data?.me).toMatchObject({ isAdmin: false })

    seedProfile(true)
    resetRequestCache()
    expect((await execute(`query { me { isAdmin } }`)).data?.me).toMatchObject({ isAdmin: true })
  })
})

// The profile read is memoized per request; re-seeding within one test needs a
// fresh request context, exactly like a new HTTP call would get.
const resetRequestCache = () => {
  const context: Record<string, unknown> = {}
  ;(globalThis as unknown as { useEvent: () => unknown }).useEvent = () => ({ context })
}
