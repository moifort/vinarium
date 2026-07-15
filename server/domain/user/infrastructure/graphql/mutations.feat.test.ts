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

const completeOnboarding = (rows: number, cols: number) => `
  mutation {
    completeOnboarding(input: { firstName: "Thibaut", rows: ${rows}, cols: ${cols} }) {
      firstName
      onboardingCompleted
      onboardingCompletedAt
    }
  }
`

describe('me query', () => {
  test('reports onboarding not done for a fresh user', async () => {
    const result = await execute(`query { me { firstName onboardingCompleted } }`)
    expect(result.errors).toBeUndefined()
    expect(result.data?.me).toMatchObject({ firstName: null, onboardingCompleted: false })
  })
})

describe('completeOnboarding mutation', () => {
  test('persists the profile and reflects it in me', async () => {
    const mutation = await execute(completeOnboarding(10, 5))
    expect(mutation.errors).toBeUndefined()
    expect(mutation.data?.completeOnboarding).toMatchObject({
      firstName: 'Thibaut',
      onboardingCompleted: true,
    })
    expect(
      (mutation.data as { completeOnboarding: { onboardingCompletedAt: string } })
        .completeOnboarding.onboardingCompletedAt,
    ).toBeString()

    const me = await execute(`query { me { firstName onboardingCompleted } }`)
    expect(me.data?.me).toMatchObject({ firstName: 'Thibaut', onboardingCompleted: true })
    expect(fake.snapshot('cellar-configs').get('usr_user-1')).toMatchObject({ rows: 10, cols: 5 })
  })

  test.each([
    [0, 8],
    [101, 8],
    [6, 0],
    [6, 101],
  ])('rejects out-of-range dimensions %p x %p with BAD_USER_INPUT', async (rows, cols) => {
    const result = await execute(completeOnboarding(rows, cols))
    expect(result.errors?.[0]?.extensions?.code).toBe('BAD_USER_INPUT')
  })
})
