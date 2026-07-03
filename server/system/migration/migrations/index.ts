import type { Migration } from '~/system/migration/types'
import { migration0001 } from './0001-backfill-beverage-type'

export const migrations: Migration[] = [migration0001]
