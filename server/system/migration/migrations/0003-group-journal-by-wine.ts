import { groupBy } from 'lodash-es'
import { MigrationName, MigrationVersion } from '~/system/migration/primitives'
import type { Migration } from '~/system/migration/types'

type StoredEntry = { wineId: string }

export const migration0003: Migration = {
  version: MigrationVersion(3),
  name: MigrationName('Group journal entries by wineId'),
  migrate: async ({ storage }) => {
    const journal = storage('journal')
    const keys = await journal.getKeys('entries')
    if (keys.length === 0) return { ok: true, transformed: 0 }

    const entries = await Promise.all(
      keys.map(async (key) => ({ key, entry: await journal.getItem<StoredEntry>(key) })),
    )
    const validEntries = entries.filter(
      (item): item is { key: string; entry: StoredEntry } => item.entry !== null,
    )
    const grouped = groupBy(validEntries, ({ entry }) => entry.wineId)

    await Promise.all(
      Object.entries(grouped).map(([wineId, items]) =>
        journal.setItem(
          `by-wine:${wineId}`,
          items.map(({ entry }) => entry),
        ),
      ),
    )
    await Promise.all(keys.map((key) => journal.removeItem(key)))

    return { ok: true, transformed: validEntries.length }
  },
}
