// One-shot migration of the legacy Casa file storage (.data/db/) into Firestore.
// The old server was single-user: every record gets stamped with the target
// Firebase Auth user's id, mirroring PortabilityUseCase.importAll.
//
// Usage:
//   bun scripts/migrate-casa-to-firestore.ts --dry-run
//   FIRESTORE_EMULATOR_HOST=localhost:8080 TARGET_USER_ID=test-user bun scripts/migrate-casa-to-firestore.ts
//   GOOGLE_CLOUD_PROJECT=cave-a-vin bun scripts/migrate-casa-to-firestore.ts
//
// TARGET_USER_ID overrides user resolution; otherwise the single Firebase Auth
// account is auto-detected (fails loudly if there is not exactly one).
// CASA_DATA_DIR overrides the source directory (defaults to .data/db).
import { readdir } from 'node:fs/promises'
import { join } from 'node:path'
import { getAuth } from 'firebase-admin/auth'
import { chunk } from 'lodash-es'
import { z } from 'zod'
import * as cellarRepo from '~/domain/cellar/infrastructure/repository'
import type { CellarBottle } from '~/domain/cellar/types'
import * as journalRepo from '~/domain/journal/infrastructure/repository'
import type { JournalEntry } from '~/domain/journal/types'
import { UserId } from '~/domain/shared/primitives'
import type { UserId as UserIdType } from '~/domain/shared/types'
import * as tastingRepo from '~/domain/tasting/infrastructure/repository'
import type { TastingNote } from '~/domain/tasting/types'
import * as wineRepo from '~/domain/wine/infrastructure/repository'
import type { Wine } from '~/domain/wine/types'

const isoDate = z.coerce.date()

// strictObject everywhere: the live Casa server may carry fields these
// hand-written schemas don't know about — abort rather than silently drop
// data in a one-shot migration.
const wineSchema = z.strictObject({
  id: z.string().min(1),
  name: z.string().min(1),
  color: z.enum(['red', 'white', 'rosé', 'sparkling', 'sweet']),
  domain: z.string().optional(),
  vintage: z.number().optional(),
  appellation: z.string().optional(),
  region: z.string().optional(),
  country: z.string().optional(),
  grapeVarieties: z.array(z.string()).optional(),
  classification: z.string().optional(),
  purchasePrice: z.number().optional(),
  purchaseDate: z.string().optional(),
  drinkFrom: z.number().optional(),
  drinkUntil: z.number().optional(),
  notes: z.string().optional(),
  giftedBy: z.string().optional(),
  servingTemperature: z.number().optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  placeName: z.string().optional(),
  createdAt: isoDate,
  updatedAt: isoDate,
})

const cellarSchema = z.strictObject({
  wineId: z.string().min(1),
  row: z.number().int().min(0),
  col: z.number().int().min(0),
  createdAt: isoDate,
  updatedAt: isoDate,
})

const tastingSchema = z.strictObject({
  wineId: z.string().min(1),
  consumedDate: isoDate.optional(),
  rating: z.number().optional(),
  tastingNotes: z.string().optional(),
  contacts: z.array(z.string()).optional(),
  shortlist: z.boolean().optional(),
})

// The old journal stored one array per wine, entries carrying dateIn or
// dateOut depending on direction; the new model is one flat document per
// movement with a single `date` field.
const journalFileSchema = z.array(
  z.discriminatedUnion('type', [
    z.strictObject({
      type: z.literal('in'),
      wineId: z.string().min(1),
      dateIn: isoDate,
      row: z.number().int().min(0),
      col: z.number().int().min(0),
    }),
    z.strictObject({
      type: z.literal('out'),
      wineId: z.string().min(1),
      dateOut: isoDate,
      row: z.number().int().min(0),
      col: z.number().int().min(0),
    }),
  ]),
)

const readCollection = async (dataDir: string, dir: string) => {
  const path = join(dataDir, dir)
  const files = (await readdir(path)).filter((name) => !name.startsWith('.'))
  return Promise.all(
    files.map(async (name) => {
      const text = await Bun.file(join(path, name)).text()
      try {
        return { key: name, raw: JSON.parse(text) as unknown }
      } catch {
        throw new Error(`invalid JSON in ${join(path, name)}`)
      }
    }),
  )
}

const resolveUserId = async (dryRun: boolean) => {
  if (process.env.TARGET_USER_ID) return UserId(process.env.TARGET_USER_ID)
  if (dryRun) return UserId('dry-run-user')
  // listUsers targets PRODUCTION Auth even under FIRESTORE_EMULATOR_HOST
  // (only FIREBASE_AUTH_EMULATOR_HOST redirects it) — emulator runs must
  // set TARGET_USER_ID instead.
  const { users } = await getAuth().listUsers()
  if (users.length !== 1) {
    const found = users.map((u) => `${u.uid} (${u.email ?? u.displayName ?? '?'})`).join(', ')
    throw new Error(
      `Expected exactly one Firebase Auth account, found ${users.length}: [${found}]. ` +
        'Set TARGET_USER_ID to pick one.',
    )
  }
  const only = users[0]
  if (!only) throw new Error('unreachable: users[0] missing after length check')
  console.log(`Auto-detected target user: ${only.uid} (${only.email ?? only.displayName ?? '?'})`)
  return UserId(only.uid)
}

const fail = (context: string, error: z.ZodError): never => {
  throw new Error(`${context}: ${z.prettifyError(error)}`)
}

type MigrateOptions = { dataDir: string; userId: UserIdType; dryRun: boolean }

export const migrate = async ({ dataDir, userId, dryRun }: MigrateOptions) => {
  const [wineFiles, cellarFiles, tastingFiles, journalFiles] = await Promise.all([
    readCollection(dataDir, 'wines'),
    readCollection(dataDir, 'cellar/entries'),
    readCollection(dataDir, 'tasting/entries'),
    readCollection(dataDir, 'journal/by-wine'),
  ])

  const wines = wineFiles.map(({ key, raw }) => {
    const parsed = wineSchema.safeParse(raw)
    if (!parsed.success) return fail(`wine ${key}`, parsed.error)
    return { ...parsed.data, userId } as unknown as Wine
  })

  const cellar = cellarFiles.map(({ key, raw }) => {
    const parsed = cellarSchema.safeParse(raw)
    if (!parsed.success) return fail(`cellar ${key}`, parsed.error)
    return { ...parsed.data, userId } as unknown as CellarBottle
  })

  const tasting = tastingFiles.map(({ key, raw }) => {
    const parsed = tastingSchema.safeParse(raw)
    if (!parsed.success) return fail(`tasting ${key}`, parsed.error)
    return { ...parsed.data, userId } as unknown as TastingNote
  })

  const journal = journalFiles.flatMap(({ key, raw }) => {
    const parsed = journalFileSchema.safeParse(raw)
    if (!parsed.success) return fail(`journal ${key}`, parsed.error)
    return parsed.data.map((entry) => {
      const { type, wineId, row, col } = entry
      const date = entry.type === 'in' ? entry.dateIn : entry.dateOut
      return { type, wineId, row, col, date, userId } as unknown as JournalEntry
    })
  })

  // Integrity: every referenced wine must exist in the migrated set.
  const wineIds = new Set(wines.map((wine) => wine.id as string))
  const orphans = [
    ...cellar.filter((row) => !wineIds.has(row.wineId as string)).map((r) => `cellar:${r.wineId}`),
    ...tasting
      .filter((row) => !wineIds.has(row.wineId as string))
      .map((r) => `tasting:${r.wineId}`),
    ...journal
      .filter((row) => !wineIds.has(row.wineId as string))
      .map((r) => `journal:${r.wineId}`),
  ]
  if (orphans.length > 0) console.warn(`⚠ ${orphans.length} orphan record(s):`, orphans)

  const counts = {
    wines: wines.length,
    cellar: cellar.length,
    tasting: tasting.length,
    journal: journal.length,
    orphans: orphans.length,
  }
  console.log(
    `Mapped from ${dataDir}: ${counts.wines} wines, ${counts.cellar} cellar bottles, ` +
      `${counts.tasting} tasting notes, ${counts.journal} journal events (target user ${userId})`,
  )

  if (dryRun) {
    console.log('\n--dry-run: nothing written. Samples:')
    console.log('wine:', JSON.stringify(wines[0], null, 2))
    console.log('cellar:', JSON.stringify(cellar[0], null, 2))
    console.log('tasting:', JSON.stringify(tasting[0], null, 2))
    console.log('journal:', JSON.stringify(journal[0], null, 2))
    return counts
  }

  // Journal docs have auto-generated ids: purge the user's entries first so a
  // re-run does not duplicate movements. Other domains upsert deterministically.
  // Safe to re-run ONLY while Casa remains the source of truth — once the user
  // starts writing through the new app, this purge would destroy those movements.
  const existingJournal = await journalRepo.findAllByUser(userId)
  if (existingJournal.length > 0)
    console.warn(`⚠ purging ${existingJournal.length} existing journal entries for ${userId}`)
  await journalRepo.removeAllByUser(userId)

  const saveAll = async <T>(rows: T[], save: (row: T) => Promise<unknown>) => {
    for (const batch of chunk(rows, 50)) await Promise.all(batch.map(save))
  }
  await Promise.all([
    saveAll(wines, (row) => wineRepo.save(row)),
    saveAll(cellar, (row) => cellarRepo.save(row)),
    saveAll(tasting, (row) => tastingRepo.save(row)),
    saveAll(journal, (row) => journalRepo.save(row)),
  ])

  console.log('✔ Migration written to Firestore.')
  return counts
}

if (import.meta.main) {
  const dryRun = process.argv.includes('--dry-run')
  const dataDir = process.env.CASA_DATA_DIR ?? '.data/db'
  const userId = await resolveUserId(dryRun)
  await migrate({ dataDir, userId, dryRun })
}
