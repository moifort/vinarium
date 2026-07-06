import type { Beverage } from '~/domain/beverage/types'
import type { CellarBottle } from '~/domain/cellar/types'
import type { Gift } from '~/domain/gift/types'
import type { JournalEntry } from '~/domain/journal/types'
import type { Recommendation } from '~/domain/recommendation/types'
import type { UserId } from '~/domain/shared/types'
import type { TastingNote } from '~/domain/tasting/types'

export const EXPORT_SCHEMA_VERSION = 1 as const

export type ExportEnvelope = {
  schemaVersion: typeof EXPORT_SCHEMA_VERSION
  exportedAt: Date
  userId: UserId
  wines: Beverage[]
  cellar: CellarBottle[]
  tasting: TastingNote[]
  recommendation: Recommendation[]
  gift: Gift[]
  journal: JournalEntry[]
}

export type ImportResult = {
  wines: number
  cellar: number
  tasting: number
  recommendation: number
  gift: number
  journal: number
}
