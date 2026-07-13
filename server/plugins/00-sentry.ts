import * as Sentry from '@sentry/node'
import { instrumentDomains } from '#domain-instrumentation'
import { config } from '~/system/config/index'

export default defineNitroPlugin((nitroApp) => {
  const { sentryDsn } = config()
  if (!sentryDsn) return

  Sentry.init({
    dsn: sentryDsn,
    environment: process.env.NODE_ENV ?? 'development',
    tracesSampleRate: 1.0,
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

  nitroApp.hooks.hook('error', async (error, { event }) => {
    const statusCode = (error as { statusCode?: number }).statusCode
    if (statusCode && statusCode >= 400 && statusCode < 500) return

    Sentry.captureException(error, {
      extra: {
        path: event?.path,
        method: event?.method,
      },
    })
    // Cloud Functions gen2 throttles the CPU once the response is sent —
    // flush now or the event may never leave the instance.
    await Sentry.flush(2000)
  })
})
