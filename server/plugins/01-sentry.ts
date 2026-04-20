import * as Sentry from '@sentry/bun'
import { instrumentDomains } from '#domain-instrumentation'
import { config } from '~/system/config/index'

export default defineNitroPlugin((nitroApp) => {
  const { sentryDsn } = config()
  if (!sentryDsn) return

  Sentry.init({
    dsn: sentryDsn,
    tracesSampleRate: 1.0,
    integrations: (defaults) =>
      // BunServer integration is incompatible with Nitro's localFetch pattern
      defaults.filter((integration) => integration.name !== 'BunServer'),
  })

  instrumentDomains()

  const originalHandler = nitroApp.h3App.handler
  nitroApp.h3App.handler = ((event) =>
    Sentry.startSpan({ name: `${event.method} ${event.path}`, op: 'http.server' }, async (span) => {
      const result = await originalHandler(event)
      const route = event.context.matchedRoute?.path
      if (route) span.updateName(`${event.method} ${route}`)
      return result
    })) as typeof originalHandler

  nitroApp.hooks.hook('error', (error, { event }) => {
    const statusCode = (error as { statusCode?: number }).statusCode
    if (statusCode && statusCode >= 400 && statusCode < 500) return

    Sentry.captureException(error, {
      extra: { path: event?.path, method: event?.method },
    })
  })
})
