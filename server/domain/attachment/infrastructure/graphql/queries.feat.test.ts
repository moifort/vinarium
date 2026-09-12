import { beforeEach, describe, expect, mock, test } from 'bun:test'
import { graphql } from 'graphql'
import type { ObjectStore } from '~/domain/attachment/infrastructure/object-store'
import type { ObjectPath, SignedUrl } from '~/domain/attachment/types'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

let signatures = 0

const fakeStore: ObjectStore = {
  uploadUrl: async (path) => `https://upload.test/${path}` as SignedUrl,
  downloadUrl: async (path) => {
    signatures++
    return `https://download.test/${path}` as SignedUrl
  },
  stat: async () => null,
  remove: async () => {},
  removeByPrefix: async () => {},
  list: async () => [],
}

mock.module('~/system/firebase', () => ({ db: fakeDb }))
mock.module('~/domain/attachment/infrastructure/object-store', () => ({
  objectStore: () => fakeStore,
}))

const { schema } = await import('~/domain/shared/graphql/schema')
const { beverageSatelliteLoaders } = await import('~/domain/shared/graphql/loaders')

const userId = 'user-1' as UserId
const wid = (n: number) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`
const aid = (n: number) => `11111111-0000-4000-8000-${String(n).padStart(12, '0')}`

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
  signatures = 0
})

const execute = (source: string) =>
  graphql({
    schema,
    source,
    contextValue: { userId, event: undefined as never, loaders: beverageSatelliteLoaders(userId) },
  })

const seedWine = (id: string) =>
  fake.seed('beverages', id, {
    id,
    userId,
    name: `Beverage ${id}`,
    beverageType: 'wine',
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
  })

const seedAttachment = (id: string, beverageId: string, createdAt: Date) =>
  fake.seed('attachments', id, {
    id,
    userId,
    beverageId,
    kind: 'image',
    contentType: 'image/jpeg',
    fileName: `${id}.jpg`,
    size: 2048,
    objectPath: `attachments/${userId}/${beverageId}/${id}` as ObjectPath,
    createdAt,
  })

describe('Beverage.attachments', () => {
  test('lists a wine files oldest first', async () => {
    seedWine(wid(1))
    seedAttachment(aid(2), wid(1), new Date('2026-03-01'))
    seedAttachment(aid(1), wid(1), new Date('2026-02-01'))

    const result = await execute(`
      { beverage(id: "${wid(1)}") { attachments { id fileName kind size url } } }
    `)

    expect(result.errors).toBeUndefined()
    const attachments = (result.data as any).beverage.attachments
    expect(attachments.map((a: any) => a.id)).toEqual([aid(1), aid(2)])
    expect(attachments[0].url).toContain(`attachments/${userId}/${wid(1)}/${aid(1)}`)
    expect(attachments[0].kind).toBe('image')
  })

  test('comes back empty on a wine nothing was attached to', async () => {
    seedWine(wid(1))

    const result = await execute(`{ beverage(id: "${wid(1)}") { attachments { id } } }`)

    expect(result.errors).toBeUndefined()
    expect((result.data as any).beverage.attachments).toEqual([])
  })

  // A signature is an API call. Selecting the list without the URL must cost none,
  // which is the whole reason `url` is resolved rather than exposed.
  test('signs nothing when the URL is not selected', async () => {
    seedWine(wid(1))
    seedAttachment(aid(1), wid(1), new Date('2026-02-01'))

    await execute(`{ beverage(id: "${wid(1)}") { attachments { id fileName } } }`)

    expect(signatures).toBe(0)
  })

  // The loader exists so a page of wines costs one keyed read, not one per row.
  test('reads once for a whole page of wines', async () => {
    for (let i = 1; i <= 3; i++) {
      seedWine(wid(i))
      seedAttachment(aid(i), wid(i), new Date('2026-02-01'))
    }
    const before = fake.queryReads

    const result = await execute(`
      { beverages(limit: 10) { items { id attachments { id } } } }
    `)

    expect(result.errors).toBeUndefined()
    const items = (result.data as any).beverages.items
    expect(items.every((item: any) => item.attachments.length === 1)).toBe(true)
    // One `in` query for the three wines, whatever the page size below 30.
    expect(fake.queryReads - before).toBeLessThanOrEqual(3)
  })
})
