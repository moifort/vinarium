import { MigrationName, MigrationVersion } from '~/system/migration/primitives'
import type { Migration } from '~/system/migration/types'

type LegacyJournalEntry = {
  type: 'in' | 'out'
  wineId: string
  rowLabel: string
  colLabel: number
  dateIn?: string
  dateOut?: string
}

type MigratedJournalEntry = {
  type: 'in' | 'out'
  wineId: string
  row: number
  col: number
  dateIn?: string
  dateOut?: string
}

export const migration0005: Migration = {
  version: MigrationVersion(5),
  name: MigrationName('Convert journal entries from display labels to raw positions'),
  migrate: async ({ storage }) => {
    const journal = storage('journal')
    const keys = await journal.getKeys('by-wine')
    if (keys.length === 0) return { ok: true, transformed: 0 }

    let transformed = 0
    await Promise.all(
      keys.map(async (key) => {
        const entries = await journal.getItem<LegacyJournalEntry[]>(key)
        if (!entries?.length) return

        const needsMigration = entries.some((e) => 'rowLabel' in e)
        if (!needsMigration) return

        const migrated: MigratedJournalEntry[] = entries.map((entry) => {
          const { rowLabel, colLabel, ...rest } = entry
          return {
            ...rest,
            row: rowLabel.charCodeAt(0) - 65,
            col: colLabel - 1,
          }
        })

        await journal.setItem(key, migrated)
        transformed++
      }),
    )

    return { ok: true, transformed }
  },
}
