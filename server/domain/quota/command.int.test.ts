import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { QuotaCommand } = await import('~/domain/quota/command')
const { QuotaQuery } = await import('~/domain/quota/query')

const user = (id: string) => id as UserId

let fake = resetFakeFirestore()

beforeEach(() => {
  fake = resetFakeFirestore()
})

describe('recording a scan', () => {
  test('starts a never-touched month at zero and counts the first scan', async () => {
    expect((await QuotaQuery.ofCurrentMonth(user('u1'))).scans as number).toBe(0)

    await QuotaCommand.record(user('u1'))

    expect((await QuotaQuery.ofCurrentMonth(user('u1'))).scans as number).toBe(1)
  })

  test('counts every scan that lands together, rather than losing one to a stale read', async () => {
    await Promise.all([
      QuotaCommand.record(user('u1')),
      QuotaCommand.record(user('u1')),
      QuotaCommand.record(user('u1')),
    ])

    expect((await QuotaQuery.ofCurrentMonth(user('u1'))).scans as number).toBe(3)
  })

  test('reads and writes the counter in one transaction, never as a bare set', async () => {
    await QuotaCommand.record(user('u1'))

    expect(fake.transactions).toHaveLength(1)
    expect(fake.directWrites).toHaveLength(0)
  })

  test('keeps one account out of another account s counter', async () => {
    await QuotaCommand.record(user('u1'))
    await QuotaCommand.record(user('u2'))
    await QuotaCommand.record(user('u2'))

    expect((await QuotaQuery.ofCurrentMonth(user('u1'))).scans as number).toBe(1)
    expect((await QuotaQuery.ofCurrentMonth(user('u2'))).scans as number).toBe(2)
  })
})

describe('reading the month s quota', () => {
  test('costs one document read, however many times it is asked in a request', async () => {
    await QuotaQuery.ofCurrentMonth(user('u1'))
    await QuotaQuery.ofCurrentMonth(user('u1'))

    expect(fake.docReads).toBe(1)
    expect(fake.queryReads).toBe(0)
  })

  test('sees a scan recorded earlier in the same request', async () => {
    await QuotaQuery.ofCurrentMonth(user('u1'))
    await QuotaCommand.record(user('u1'))

    expect((await QuotaQuery.ofCurrentMonth(user('u1'))).scans as number).toBe(1)
  })
})
