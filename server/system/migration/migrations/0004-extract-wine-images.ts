import { MigrationName, MigrationVersion } from '~/system/migration/primitives'
import type { Migration } from '~/system/migration/types'

export const migration0004: Migration = {
  version: MigrationVersion(4),
  name: MigrationName('Extract wine images to separate storage'),
  migrate: async ({ storage }) => {
    const wines = storage('wines')
    const images = storage('wine-images')
    const keys = await wines.getKeys()
    if (keys.length === 0) return { ok: true, transformed: 0 }

    const results = await Promise.all(
      keys.map(async (key) => {
        const wine = await wines.getItem<{ imageBase64?: string }>(key)
        if (!wine?.imageBase64) return false
        const { imageBase64, ...wineWithoutImage } = wine
        await images.setItem(key, imageBase64)
        await wines.setItem(key, wineWithoutImage)
        return true
      }),
    )
    return { ok: true, transformed: results.filter(Boolean).length }
  },
}
