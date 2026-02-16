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
  },
})
