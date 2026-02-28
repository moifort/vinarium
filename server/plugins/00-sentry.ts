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
        // BunServer integration is incompatible with Nitro's localFetch pattern
        .filter((integration) => integration.name !== 'BunServer')
        .concat(Sentry.fsIntegration({ recordFilePaths: true })),
  })

  const originalHandler = nitroApp.h3App.handler
  nitroApp.h3App.handler = ((event) =>
    Sentry.continueTrace(
      {
        sentryTrace: getHeader(event, 'sentry-trace') ?? '',
        baggage: getHeader(event, 'baggage') ?? '',
      },
      () =>
        Sentry.startSpan({ name: `${event.method} ${event.path}`, op: 'http.server' }, () =>
          originalHandler(event),
        ),
    )) as typeof originalHandler

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
