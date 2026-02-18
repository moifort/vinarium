export default defineNitroConfig({
  compatibilityDate: '2026-02-06',
  srcDir: 'server',
  runtimeConfig: {
    anthropicApiKey: '',
    googleApiKey: '',
    apiToken: '',
  },
  storage: {
    wines: { driver: 'fs', base: './.data/db/wines' },
    cellar: { driver: 'fs', base: './.data/db/cellar' },
    'cellar-log': { driver: 'fs', base: './.data/db/cellar-log' }, // kept for migration 0002
    journal: { driver: 'fs', base: './.data/db/journal' },
    tasting: { driver: 'fs', base: './.data/db/tasting' },
    'migration-meta': { driver: 'fs', base: './.data/db/migration-meta' },
  },
})
