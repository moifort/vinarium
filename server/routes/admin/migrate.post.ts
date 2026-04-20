import { migrations } from '~/system/migration/migrations'
import { runMigrations } from '~/system/migration/runner'

export default defineEventHandler(async () => runMigrations(migrations))
