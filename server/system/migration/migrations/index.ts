import { migration0001 } from '~/system/migration/migrations/0001-init'
import { migration0002 } from '~/system/migration/migrations/0002-rename-cellar-log-to-journal'
import { migration0003 } from '~/system/migration/migrations/0003-group-journal-by-wine'
import type { Migration } from '~/system/migration/types'

export const migrations: Migration[] = [migration0001, migration0002, migration0003]
