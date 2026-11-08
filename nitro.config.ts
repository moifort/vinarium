import { generateDomainInstrumentation } from './server/system/sentry/generate-domain-instrumentation'

/** The packages a production build keeps as files rather than bundling in. */
const BUNDLED_AS_FILES =
  /firebase-functions|firebase-admin|@google-cloud\/|google-auth-library|google-gax|gaxios|gcp-metadata|gtoken|@grpc\/|protobufjs|proto3-json-serializer|@sentry\//

export default defineNitroConfig({
  compatibilityDate: '2026-02-06',
  experimental: { asyncContext: true },
  srcDir: 'server',
  ignore: ['**/*.test.ts'],
  preset: 'firebase',
  firebase: {
    gen: 2,
    nodeVersion: '22',
    httpsOptions: {
      region: 'europe-west3',
      memory: '512MiB',
      timeoutSeconds: 60,
      concurrency: 80,
    },
  },
  // Rollup minifies the whole backend into one file, so an unmapped stack trace
  // points at a column of index.mjs. The maps are uploaded to Sentry at deploy
  // time and stay out of the deployed bundle.
  sourceMap: true,
  // Cold starts took about 9 s (2026-11-08), most of it loading dependencies
  // before the first line of our bundle: the firebase preset leaves them as
  // thousands of files in node_modules, and Cloud Run pays every one of them.
  // Bundling them in, as Nitro 3 does by default, cut that load by 41 % on
  // Shiori, which runs the same stack. The Firebase and gRPC stack stays on
  // disk: google-gax reads its .proto files through `__dirname`, which has no
  // meaning inside an ES module, and firebase-admin requires
  // @google-cloud/firestore by deep path. Sentry stays whole: its injection
  // package registers a module hook it locates by its own package name, and
  // keeping only that package out would load a second copy of @sentry/core.
  externals: {
    external: [BUNDLED_AS_FILES],
    inline: [(id) => !BUNDLED_AS_FILES.test(id)],
  },
  // jws does `require('stream')` and expects the Stream constructor, not the
  // module namespace rollup hands a bare require of a builtin.
  commonJS: { requireReturnsDefault: 'preferred' },
  rollupConfig: {
    treeshake: {
      moduleSideEffects: (id) => id.includes('/graphql/') || id.includes('node_modules'),
    },
  },
  virtual: {
    '#domain-instrumentation': generateDomainInstrumentation,
  },
  runtimeConfig: {
    googleApiKey: '',
    adminToken: '',
    sentryDsn: '',
    // Baked in at build time by the deploy workflow (the git SHA), so Sentry can
    // tell which deploy an error comes from and pick the matching source maps.
    sentryRelease: process.env.SENTRY_RELEASE ?? '',
    devUserId: '',
    scanStub: '',
    appleEnvironment: '',
    premiumUserIds: '',
    ascIssuerId: '',
    ascKeyId: '',
    ascPrivateKey: '',
    ascVendorNumber: '',
    gcpBillingTable: '',
    // The project the function runs in, set by Terraform: what the billing
    // export's rows are filtered on, and where the BigQuery job runs.
    firebaseProjectId: '',
    // The GA4 property the app reports to, for the admin screen's sessions.
    ga4PropertyId: '',
    attachmentsBucket: '',
    // Dev only: the origin the local object store points its URLs at, so the
    // simulator downloads an attachment from the same server it queried.
    publicBaseUrl: 'http://127.0.0.1:3000',
  },
})
