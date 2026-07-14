import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { CellarCols, CellarRows } from '~/domain/cellar/types'
import type { HouseholdId, HouseholdMember } from '~/domain/household/types'
import type { PersonName, UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { UserUseCase } = await import('~/domain/user/use-case')
const { UserQuery } = await import('~/domain/user/query')
const { CellarQuery } = await import('~/domain/cellar/query')

const user = (id: string) => id as UserId

const member = (id: string, householdId: string): HouseholdMember => ({
  userId: user(id),
  householdId: householdId as HouseholdId,
  displayName: id as PersonName,
  role: 'owner',
  joinedAt: new Date('2026-01-01'),
})

let fake = resetFakeFirestore()

beforeEach(() => {
  fake = resetFakeFirestore()
})

describe('UserUseCase.completeOnboarding', () => {
  test('writes the profile and the cellar config together', async () => {
    await UserUseCase.completeOnboarding(user('u1'), {
      firstName: 'Thibaut' as PersonName,
      rows: 10 as CellarRows,
      cols: 5 as CellarCols,
    })

    const me = await UserQuery.me(user('u1'))
    expect(me.firstName as string).toBe('Thibaut')
    expect(me.onboardingCompletedAt).toBeInstanceOf(Date)

    const config = await CellarQuery.config(user('u1'))
    expect(config).toMatchObject({ rows: 10, cols: 5 })
  })

  test('a solo user stores config under a usr_ scope key', async () => {
    await UserUseCase.completeOnboarding(user('solo'), {
      firstName: 'Marie' as PersonName,
      rows: 8 as CellarRows,
      cols: 6 as CellarCols,
    })
    expect(fake.snapshot('cellar-configs').get('usr_solo')).toMatchObject({ rows: 8, cols: 6 })
  })

  test('a household member stores config under the shared hh_ scope key', async () => {
    fake.seed('household-members', 'u1', member('u1', 'h1'))
    await UserUseCase.completeOnboarding(user('u1'), {
      firstName: 'Thibaut' as PersonName,
      rows: 12 as CellarRows,
      cols: 7 as CellarCols,
    })
    expect(fake.snapshot('cellar-configs').get('hh_h1')).toMatchObject({ rows: 12, cols: 7 })
  })

  test('never overwrites the shared grid a housemate already configured', async () => {
    fake.seed('household-members', 'a', member('a', 'h1'))
    fake.seed('household-members', 'b', member('b', 'h1'))
    fake.seed('cellar-configs', 'hh_h1', { rows: 12, cols: 7 })

    // Member B onboards later and picks a smaller size — the grid must not shrink.
    await UserUseCase.completeOnboarding(user('b'), {
      firstName: 'Marie' as PersonName,
      rows: 6 as CellarRows,
      cols: 5 as CellarCols,
    })

    expect(fake.snapshot('cellar-configs').get('hh_h1')).toMatchObject({ rows: 12, cols: 7 })
    // B is still onboarded — only the profile was written, not the config.
    expect((await UserQuery.me(user('b'))).firstName as string).toBe('Marie')
  })

  test('both writes land in a single committed batch (atomic)', async () => {
    await UserUseCase.completeOnboarding(user('u1'), {
      firstName: 'Thibaut' as PersonName,
      rows: 10 as CellarRows,
      cols: 5 as CellarCols,
    })
    expect(fake.batches).toHaveLength(1)
    expect(fake.batches[0].commits).toBe(1)
    expect(fake.batches[0].ops).toHaveLength(2)
  })
})
