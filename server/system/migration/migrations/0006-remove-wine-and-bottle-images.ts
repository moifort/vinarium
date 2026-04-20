import { rm } from 'node:fs/promises'
import { MigrationName, MigrationVersion } from '~/system/migration/primitives'
import type { Migration } from '~/system/migration/types'

const DATA_DIRS = ['./.data/db/wine-images', './.data/db/bottle-images']

export const migration0006: Migration = {
  version: MigrationVersion(6),
  name: MigrationName('Remove wine-images and bottle-images storage'),
  migrate: async () => {
    await Promise.all(DATA_DIRS.map((dir) => rm(dir, { recursive: true, force: true })))
    return { ok: true, transformed: DATA_DIRS.length }
  },
}
