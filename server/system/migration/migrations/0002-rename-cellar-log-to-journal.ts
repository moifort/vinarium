import { MigrationName, MigrationVersion } from '~/system/migration/primitives'
import type { Migration } from '~/system/migration/types'

export const migration0002: Migration = {
  version: MigrationVersion(2),
  name: MigrationName('Rename cellar-log storage to journal'),
  migrate: async ({ storage }) => {
    const source = storage('cellar-log')
    const target = storage('journal')
    const keys = await source.getKeys()
    if (keys.length === 0) return { ok: true, transformed: 0 }
    for (const key of keys) {
      const value = await source.getItem(key)
      await target.setItem(key, value)
      await source.removeItem(key)
    }
    return { ok: true, transformed: keys.length }
  },
}
