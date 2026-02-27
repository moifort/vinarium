import * as Sentry from '@sentry/bun'
import { config } from '~/system/config/index'

export default defineNitroPlugin((nitroApp) => {
  const { sentryDsn } = config()
  if (!sentryDsn) return

  Sentry.init({
    dsn: sentryDsn,
    tracesSampleRate: 1.0,
    integrations: (defaults) =>
      defaults
        .filter((i) => i.name !== 'BunServer')
        .concat(Sentry.fsIntegration({ recordFilePaths: true })),
  })

  const originalLocalFetch = nitroApp.localFetch.bind(nitroApp)
  nitroApp.localFetch = (req, init) => {
    const headers = init?.headers
    const sentryTrace =
      headers instanceof Headers ? (headers.get('sentry-trace') ?? undefined) : undefined
    const baggage = headers instanceof Headers ? (headers.get('baggage') ?? undefined) : undefined
    const path =
      typeof req === 'string' ? req : req instanceof URL ? req.pathname : new URL(req.url).pathname
    const name = `${init?.method ?? 'GET'} ${path}`

    return Sentry.continueTrace({ sentryTrace, baggage }, () =>
      Sentry.startSpan({ name, op: 'http.server' }, () => originalLocalFetch(req, init)),
    )
  }

  nitroApp.hooks.hook('error', (error, { event }) => {
    const statusCode = (error as { statusCode?: number }).statusCode
    if (statusCode && statusCode >= 400 && statusCode < 500) return

    Sentry.captureException(error, {
      extra: {
        path: event?.path,
        method: event?.method,
      },
    })
  })
})
