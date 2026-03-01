export default defineEventHandler(async () => {
  for (const name of [
    'wines',
    'wine-images',
    'cellar',
    'journal',
    'tasting',
    'gift',
    'recommendation',
    'migration-meta',
  ]) {
    const storage = useStorage(name)
    const keys = await storage.getKeys()
    for (const key of keys) await storage.removeItem(key)
  }
  return { status: 200, message: 'Database reset' }
})
