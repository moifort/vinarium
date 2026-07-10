import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { PortabilityUseCase } = await import('./use-case')
const { EXPORT_SCHEMA_VERSION } = await import('./types')

const userId = 'user-1' as UserId
const wid = (n: number) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
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

describe('PortabilityUseCase.exportAll', () => {
  test('reads raw records from every domain through their public queries', async () => {
    seedWine(wid(1))
    fake.seed('cellar', `${userId}_${wid(1)}`, {
      userId,
      beverageId: wid(1),
      row: 0,
      col: 0,
      createdAt: new Date('2026-01-02'),
      updatedAt: new Date('2026-01-02'),
    })
    fake.seed('tasting', `${userId}_${wid(1)}`, { userId, beverageId: wid(1), favorite: true })

    const envelope = await PortabilityUseCase.exportAll(userId)

    expect(envelope.schemaVersion).toBe(EXPORT_SCHEMA_VERSION)
    expect(envelope.wines).toHaveLength(1)
    expect(envelope.cellar).toHaveLength(1)
    expect(envelope.tasting).toHaveLength(1)
    // Cellar records are raw (no grid labels leak into a backup).
    expect(envelope.cellar[0]).not.toHaveProperty('rowLabel')
  })
})

describe('PortabilityUseCase.importAll', () => {
  test('replaces the collections and re-stamps the importing user', async () => {
    // Pre-existing data under this account must be wiped by the restore.
    seedWine(wid(99))

    const envelope = {
      schemaVersion: EXPORT_SCHEMA_VERSION,
      exportedAt: new Date('2026-02-01').toISOString(),
      userId: 'other-account',
      wines: [
        {
          id: wid(1),
          userId: 'other-account',
          name: 'Imported',
          beverageType: 'wine',
          createdAt: new Date('2026-01-01').toISOString(),
          updatedAt: new Date('2026-01-01').toISOString(),
        },
      ],
      cellar: [],
      tasting: [{ userId: 'other-account', beverageId: wid(1), favorite: true }],
      recommendation: [],
      gift: [],
      journal: [],
    }

    const result = await PortabilityUseCase.importAll(userId, JSON.stringify(envelope))

    expect(result).toEqual({
      wines: 1,
      cellar: 0,
      tasting: 1,
      recommendation: 0,
      gift: 0,
      journal: 0,
    })
    const wines = fake.snapshot('beverages')
    expect(wines.has(wid(99))).toBe(false) // old data wiped
    expect(wines.get(wid(1))?.userId).toBe(userId) // re-stamped to the importer
    expect(fake.snapshot('tasting').get(`${userId}_${wid(1)}`)?.userId).toBe(userId)
  })

  test('rejects invalid json and an unsupported schema version', async () => {
    expect(await PortabilityUseCase.importAll(userId, 'not json')).toEqual({
      error: 'invalid-json',
    })
    const wrongVersion = JSON.stringify({
      schemaVersion: EXPORT_SCHEMA_VERSION + 1,
      exportedAt: new Date('2026-02-01').toISOString(),
      userId,
      wines: [],
      cellar: [],
      tasting: [],
      recommendation: [],
      gift: [],
      journal: [],
    })
    expect(await PortabilityUseCase.importAll(userId, wrongVersion)).toEqual({
      error: `unsupported-schema-version:${EXPORT_SCHEMA_VERSION + 1}`,
    })
  })

  test('never touches a household member’s records', async () => {
    // A housemate's bottle and wine sit in the shared collections under their id.
    fake.seed('beverages', wid(50), {
      id: wid(50),
      userId: 'marie',
      name: 'Marie’s wine',
      beverageType: 'wine',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    })
    fake.seed('cellar', `marie_${wid(50)}`, {
      userId: 'marie',
      beverageId: wid(50),
      row: 5,
      col: 5,
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    })

    const envelope = {
      schemaVersion: EXPORT_SCHEMA_VERSION,
      exportedAt: new Date('2026-02-01').toISOString(),
      userId,
      wines: [],
      cellar: [],
      tasting: [],
      recommendation: [],
      gift: [],
      journal: [],
    }

    await PortabilityUseCase.importAll(userId, JSON.stringify(envelope))

    // The wipe is scoped to the importer, so marie's data survives intact.
    expect(fake.snapshot('beverages').has(wid(50))).toBe(true)
    expect(fake.snapshot('cellar').has(`marie_${wid(50)}`)).toBe(true)
  })
})
