import { migration0001 } from '~/system/migration/migrations/0001-init'
import { migration0002 } from '~/system/migration/migrations/0002-rename-cellar-log-to-journal'
import { migration0003 } from '~/system/migration/migrations/0003-group-journal-by-wine'
import { migration0004 } from '~/system/migration/migrations/0004-extract-wine-images'
import { migration0005 } from '~/system/migration/migrations/0005-journal-positions-to-raw'
import { migration0006 } from '~/system/migration/migrations/0006-remove-wine-and-bottle-images'
import type { Migration } from '~/system/migration/types'

export const migrations: Migration[] = [
  migration0001,
  migration0002,
  migration0003,
  migration0004,
  migration0005,
  migration0006,
]
