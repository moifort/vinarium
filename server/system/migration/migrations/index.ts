import type { Migration } from '~/system/migration/types'

// Firestore is provisioned from scratch as part of the Firebase migration.
// Add new migration files here as the schema evolves.
export const migrations: Migration[] = []
