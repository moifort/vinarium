import { beforeEach, describe, expect, test } from 'bun:test'
import { createFakeFirestore, type FakeFirestore } from '~/test/fake-firestore'
import { migration0005 } from './0005-gifted-by-to-gift'

let fake: FakeFirestore

beforeEach(() => {
  fake = createFakeFirestore()
})

describe('migration 0005 gifted-by-to-gift', () => {
  test('restructures an existing gift record into the given facet', async () => {
    fake.seed('gift', 'u1_w1', {
      userId: 'u1',
      beverageId: 'w1',
      giftedDate: new Date('2026-01-01'),
      recipientName: 'Bob',
    })

    await migration0005.migrate({ db: fake.db })

    expect(fake.snapshot('gift').get('u1_w1')).toEqual({
      userId: 'u1',
      beverageId: 'w1',
      given: { date: new Date('2026-01-01'), recipientName: 'Bob' },
    })
  })

  test('moves a wine giftedBy into the gift received facet and drops the field', async () => {
    fake.seed('wines', 'w1', { id: 'w1', userId: 'u1', name: 'Margaux', giftedBy: 'Alice' })

    await migration0005.migrate({ db: fake.db })

    expect(fake.snapshot('wines').get('w1')).toEqual({ id: 'w1', userId: 'u1', name: 'Margaux' })
    expect(fake.snapshot('gift').get('u1_w1')).toEqual({
      userId: 'u1',
      beverageId: 'w1',
      received: { from: 'Alice' },
    })
  })

  test('merges received onto an existing (restructured) given facet', async () => {
    fake.seed('wines', 'w1', { id: 'w1', userId: 'u1', name: 'Margaux', giftedBy: 'Alice' })
    fake.seed('gift', 'u1_w1', {
      userId: 'u1',
      beverageId: 'w1',
      giftedDate: new Date('2026-01-01'),
      recipientName: 'Bob',
    })

    await migration0005.migrate({ db: fake.db })

    expect(fake.snapshot('gift').get('u1_w1')).toEqual({
      userId: 'u1',
      beverageId: 'w1',
      given: { date: new Date('2026-01-01'), recipientName: 'Bob' },
      received: { from: 'Alice' },
    })
    expect(fake.snapshot('wines').get('w1')).toEqual({ id: 'w1', userId: 'u1', name: 'Margaux' })
  })

  test('leaves already-migrated data untouched', async () => {
    fake.seed('wines', 'w1', { id: 'w1', userId: 'u1', name: 'Margaux' })
    fake.seed('gift', 'u1_w1', { userId: 'u1', beverageId: 'w1', received: { from: 'Alice' } })

    const result = await migration0005.migrate({ db: fake.db })

    expect(result).toEqual({ ok: true, transformed: 0 })
    expect(fake.batches).toHaveLength(0)
  })
})
