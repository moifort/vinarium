import { generateDomainInstrumentation } from './server/system/sentry/generate-domain-instrumentation'

export default defineNitroConfig({
  compatibilityDate: '2026-02-06',
  experimental: { asyncContext: true },
  srcDir: 'server',
  ignore: ['test/**', 'routes/test/**', '**/*.test.ts'],
  virtual: {
    '#domain-instrumentation': generateDomainInstrumentation,
  },
  runtimeConfig: {
    anthropicApiKey: '',
    googleApiKey: '',
    apiToken: '',
    sentryDsn: '',
    transparentUrl: '',
  },
  storage: {
    wines: { driver: 'fs', base: './.data/db/wines' },
    'wine-images': { driver: 'fs', base: './.data/db/wine-images' },
    cellar: { driver: 'fs', base: './.data/db/cellar' },
    'cellar-log': { driver: 'fs', base: './.data/db/cellar-log' }, // kept for migration 0002
    journal: { driver: 'fs', base: './.data/db/journal' },
    tasting: { driver: 'fs', base: './.data/db/tasting' },
    'scan-cache': { driver: 'fs', base: './.data/db/scan-cache' },
    'bottle-images': { driver: 'fs', base: './.data/db/bottle-images' },
    'migration-meta': { driver: 'fs', base: './.data/db/migration-meta' },
  },
})
