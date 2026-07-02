import { beforeEach, describe, expect, mock, test } from 'bun:test'
import { mkdir, mkdtemp, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { migrate } = await import('./migrate-casa-to-firestore')

const userId = 'user-1' as UserId

const writeFixtures = async (dataDir: string) => {
  for (const dir of ['wines', 'cellar/entries', 'tasting/entries', 'journal/by-wine'])
    await mkdir(join(dataDir, dir), { recursive: true })
  const write = (path: string, data: unknown) =>
    Bun.write(join(dataDir, path), JSON.stringify(data))
  await write('wines/w1', {
    id: 'w1',
    name: 'Château Test',
    color: 'red',
    vintage: 2018,
    purchasePrice: 30,
    createdAt: '2026-02-18T18:43:29.992Z',
    updatedAt: '2026-02-18T18:43:29.992Z',
  })
  await write('wines/w2', {
    id: 'w2',
    name: 'Domaine Blanc',
    color: 'white',
    createdAt: '2026-02-19T10:00:00.000Z',
    updatedAt: '2026-02-19T10:00:00.000Z',
  })
  await write('cellar/entries/w1', {
    wineId: 'w1',
    row: 0,
    col: 2,
    createdAt: '2026-02-18T18:43:37.757Z',
    updatedAt: '2026-02-18T18:43:37.757Z',
  })
  await write('tasting/entries/w2', {
    wineId: 'w2',
    consumedDate: '2026-02-19T12:00:00.000Z',
    rating: 5,
    tastingNotes: 'Miam',
  })
  await write('journal/by-wine/w1', [
    { type: 'in', wineId: 'w1', dateIn: '2026-02-18T18:43:37.757Z', row: 0, col: 2 },
  ])
  await write('journal/by-wine/w2', [
    { type: 'in', wineId: 'w2', dateIn: '2026-02-19T10:36:15.817Z', row: 1, col: 1 },
    { type: 'out', wineId: 'w2', dateOut: '2026-02-19T12:00:00.000Z', row: 1, col: 1 },
  ])
}

let fake = resetFakeFirestore()
let dataDir = ''

beforeEach(async () => {
  fake = resetFakeFirestore()
  if (dataDir) await rm(dataDir, { recursive: true, force: true })
  dataDir = await mkdtemp(join(tmpdir(), 'casa-migration-'))
  await writeFixtures(dataDir)
})

describe('migrate', () => {
  test('stamps every record with the target userId and writes to the right collections', async () => {
    const counts = await migrate({ dataDir, userId, dryRun: false })

    expect(counts).toEqual({ wines: 2, cellar: 1, tasting: 1, journal: 3, orphans: 0 })

    const wines = fake.snapshot('wines')
    expect([...wines.keys()].sort()).toEqual(['w1', 'w2'])
    expect(wines.get('w1')).toMatchObject({
      userId,
      name: 'Château Test',
      color: 'red',
      vintage: 2018,
      createdAt: new Date('2026-02-18T18:43:29.992Z'),
    })

    const cellar = fake.snapshot('cellar')
    expect([...cellar.keys()]).toEqual(['user-1_w1'])
    expect(cellar.get('user-1_w1')).toMatchObject({ userId, wineId: 'w1', row: 0, col: 2 })

    const tasting = fake.snapshot('tasting')
    expect([...tasting.keys()]).toEqual(['user-1_w2'])
    expect(tasting.get('user-1_w2')).toMatchObject({
      userId,
      wineId: 'w2',
      rating: 5,
      consumedDate: new Date('2026-02-19T12:00:00.000Z'),
    })
  })

  test('flattens per-wine journal arrays into one document per movement with a single date', async () => {
    await migrate({ dataDir, userId, dryRun: false })

    const journal = [...fake.snapshot('journal').values()]
    expect(journal).toHaveLength(3)
    expect(journal).toContainEqual({
      type: 'in',
      userId,
      wineId: 'w2',
      row: 1,
      col: 1,
      date: new Date('2026-02-19T10:36:15.817Z'),
    })
    expect(journal).toContainEqual({
      type: 'out',
      userId,
      wineId: 'w2',
      row: 1,
      col: 1,
      date: new Date('2026-02-19T12:00:00.000Z'),
    })
    for (const entry of journal) {
      expect(entry).not.toHaveProperty('dateIn')
      expect(entry).not.toHaveProperty('dateOut')
    }
  })

  test('re-running does not duplicate journal movements', async () => {
    await migrate({ dataDir, userId, dryRun: false })
    await migrate({ dataDir, userId, dryRun: false })

    expect(fake.snapshot('journal').size).toBe(3)
    expect(fake.snapshot('wines').size).toBe(2)
    expect(fake.snapshot('cellar').size).toBe(1)
    expect(fake.snapshot('tasting').size).toBe(1)
  })

  test('dry-run maps and counts without writing anything', async () => {
    const counts = await migrate({ dataDir, userId, dryRun: true })

    expect(counts).toEqual({ wines: 2, cellar: 1, tasting: 1, journal: 3, orphans: 0 })
    expect(fake.snapshot('wines').size).toBe(0)
    expect(fake.snapshot('cellar').size).toBe(0)
    expect(fake.snapshot('tasting').size).toBe(0)
    expect(fake.snapshot('journal').size).toBe(0)
    expect(fake.directWrites).toHaveLength(0)
  })

  test('reports orphan records referencing wines missing from the export', async () => {
    await Bun.write(
      join(dataDir, 'cellar/entries/ghost'),
      JSON.stringify({
        wineId: 'ghost',
        row: 5,
        col: 5,
        createdAt: '2026-02-18T18:43:37.757Z',
        updatedAt: '2026-02-18T18:43:37.757Z',
      }),
    )

    const counts = await migrate({ dataDir, userId, dryRun: true })

    expect(counts.orphans).toBe(1)
  })

  test('fails loudly on a record that does not match the legacy schema', async () => {
    await Bun.write(
      join(dataDir, 'wines/bad'),
      JSON.stringify({ id: 'bad', name: 'No color', createdAt: 'x', updatedAt: 'x' }),
    )

    await expect(migrate({ dataDir, userId, dryRun: true })).rejects.toThrow('wine bad')
  })

  test('fails loudly on an unknown legacy field instead of silently dropping it', async () => {
    await Bun.write(
      join(dataDir, 'wines/w3'),
      JSON.stringify({
        id: 'w3',
        name: 'Cuvée Inconnue',
        color: 'red',
        cellarTemperature: 12,
        createdAt: '2026-02-18T18:43:29.992Z',
        updatedAt: '2026-02-18T18:43:29.992Z',
      }),
    )

    await expect(migrate({ dataDir, userId, dryRun: true })).rejects.toThrow('wine w3')
  })

  test('names the offending file when a record is not valid JSON', async () => {
    await Bun.write(join(dataDir, 'wines/corrupt'), '{"id": "trunc')

    await expect(migrate({ dataDir, userId, dryRun: true })).rejects.toThrow(
      join(dataDir, 'wines/corrupt'),
    )
  })
})
