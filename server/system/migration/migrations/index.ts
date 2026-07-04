import type { Migration } from '~/system/migration/types'
import { migration0001 } from './0001-backfill-beverage-type'
import { migration0002 } from './0002-merge-favorite-shortlist'

export const migrations: Migration[] = [migration0001, migration0002]
