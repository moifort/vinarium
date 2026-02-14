export default defineNitroConfig({
  compatibilityDate: '2026-02-06',
  srcDir: 'server',
  runtimeConfig: {
    anthropicApiKey: '',
  },
  storage: {
    wines: { driver: 'fs', base: './.data/db/wines' },
    cellar: { driver: 'fs', base: './.data/db/cellar' },
    finance: { driver: 'fs', base: './.data/db/finance' },
  },
  experimental: { tasks: true },
  scheduledTasks: {
    '0 0 1 * *': ['finance:snapshot'],
  },
})
