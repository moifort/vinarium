import { migration0001 } from '~/system/migration/migrations/0001-init'
import { migration0002 } from '~/system/migration/migrations/0002-rename-cellar-log-to-journal'
import type { Migration } from '~/system/migration/types'

export const migrations: Migration[] = [migration0001, migration0002]
