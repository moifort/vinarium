import { chunk } from 'lodash-es'
import { z } from 'zod'
import * as cellarRepo from '~/domain/cellar/infrastructure/repository'
import type { CellarBottle } from '~/domain/cellar/types'
import * as giftRepo from '~/domain/gift/infrastructure/repository'
import type { Gift } from '~/domain/gift/types'
import * as journalRepo from '~/domain/journal/infrastructure/repository'
import type { JournalEntry } from '~/domain/journal/types'
import {
  EXPORT_SCHEMA_VERSION,
  type ExportEnvelope,
  type ImportResult,
} from '~/domain/portability/types'
import * as recommendationRepo from '~/domain/recommendation/infrastructure/repository'
import type { Recommendation } from '~/domain/recommendation/types'
import type { UserId } from '~/domain/shared/types'
import * as tastingRepo from '~/domain/tasting/infrastructure/repository'
import type { TastingNote } from '~/domain/tasting/types'
import * as wineRepo from '~/domain/wine/infrastructure/repository'
import type { Wine } from '~/domain/wine/types'

export namespace PortabilityUseCase {
  export const exportAll = async (userId: UserId): Promise<ExportEnvelope> => {
    const [wines, cellar, tasting, recommendation, gift, journal] = await Promise.all([
      wineRepo.findAllByUser(userId),
      cellarRepo.findAllByUser(userId),
      tastingRepo.findAllByUser(userId),
      recommendationRepo.findAllByUser(userId),
      giftRepo.findAllByUser(userId),
      journalRepo.findAllByUser(userId),
    ])
    return {
      schemaVersion: EXPORT_SCHEMA_VERSION,
      exportedAt: new Date(),
      userId,
      wines,
      cellar,
      tasting,
      recommendation,
      gift,
      journal,
    }
  }

  export const importAll = async (
    userId: UserId,
    rawJson: string,
  ): Promise<ImportResult | { error: string }> => {
    let parsed: unknown
    try {
      parsed = JSON.parse(rawJson)
    } catch {
      return { error: 'invalid-json' }
    }

    const validation = envelopeSchema.safeParse(parsed)
    if (!validation.success) return { error: 'invalid-schema' }
    const envelope = validation.data

    if (envelope.schemaVersion !== EXPORT_SCHEMA_VERSION) {
      return { error: `unsupported-schema-version:${envelope.schemaVersion}` }
    }

    // Stamp the importing user across every record so a user can restore
    // an export taken under a different account (account migration).
    const stamp = <T extends { userId: string }>(rows: T[]) =>
      rows.map((row) => ({ ...row, userId }))

    const wines = stamp(envelope.wines) as Wine[]
    const cellar = stamp(envelope.cellar) as CellarBottle[]
    const tasting = stamp(envelope.tasting) as TastingNote[]
    const recommendation = stamp(envelope.recommendation) as Recommendation[]
    const gift = stamp(envelope.gift) as Gift[]
    const journal = stamp(envelope.journal) as JournalEntry[]

    await Promise.all([
      wineRepo.removeAllByUser(userId),
      cellarRepo.removeAllByUser(userId),
      tastingRepo.removeAllByUser(userId),
      recommendationRepo.removeAllByUser(userId),
      giftRepo.removeAllByUser(userId),
      journalRepo.removeAllByUser(userId),
    ])

    await Promise.all([
      saveAll(wines, (row) => wineRepo.save(row)),
      saveAll(cellar, (row) => cellarRepo.save(row)),
      saveAll(tasting, (row) => tastingRepo.save(row)),
      saveAll(recommendation, (row) => recommendationRepo.save(row)),
      saveAll(gift, (row) => giftRepo.save(row)),
      saveAll(journal, (row) => journalRepo.save(row)),
    ])

    return {
      wines: wines.length,
      cellar: cellar.length,
      tasting: tasting.length,
      recommendation: recommendation.length,
      gift: gift.length,
      journal: journal.length,
    }
  }

  const saveAll = async <T>(rows: T[], save: (row: T) => Promise<unknown>) => {
    for (const batch of chunk(rows, 50)) await Promise.all(batch.map(save))
  }
}

const dateSchema = z
  .union([z.string(), z.number(), z.date()])
  .transform((value) => (value instanceof Date ? value : new Date(value)))

const looseRecord = z.looseObject({ userId: z.string() })

const envelopeSchema = z.object({
  schemaVersion: z.literal(EXPORT_SCHEMA_VERSION),
  exportedAt: dateSchema,
  userId: z.string(),
  wines: z.array(looseRecord),
  cellar: z.array(looseRecord),
  tasting: z.array(looseRecord),
  recommendation: z.array(looseRecord),
  gift: z.array(looseRecord),
  journal: z.array(looseRecord),
})
