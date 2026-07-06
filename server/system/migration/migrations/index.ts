import type { Migration } from '~/system/migration/types'
import { migration0001 } from './0001-backfill-beverage-type'
import { migration0002 } from './0002-merge-favorite-shortlist'
import { migration0003 } from './0003-wine-subtypes'
import { migration0004 } from './0004-wine-sub-objects'

export const migrations: Migration[] = [migration0001, migration0002, migration0003, migration0004]
