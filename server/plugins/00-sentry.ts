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
      defaults
        // BunServer integration is incompatible with Nitro's localFetch pattern
        .filter((integration) => integration.name !== 'BunServer')
        .concat(Sentry.fsIntegration({ recordFilePaths: true })),
  })

  instrumentDomains()
  instrumentStorage()

  const originalHandler = nitroApp.h3App.handler
  nitroApp.h3App.handler = ((event) =>
    Sentry.continueTrace(
      {
        sentryTrace: getHeader(event, 'sentry-trace') ?? '',
        baggage: getHeader(event, 'baggage') ?? '',
      },
      () =>
        Sentry.startSpan(
          { name: `${event.method} ${event.path}`, op: 'http.server' },
          async (span) => {
            const result = await originalHandler(event)
            const route = event.context.matchedRoute?.path
            if (route) span.updateName(`${event.method} ${route}`)
            return result
          },
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

const instrumentStorage = () => {
  const rootStorage = useStorage()
  const methods = ['getItem', 'setItem', 'removeItem', 'getKeys', 'hasItem'] as const
  methods.forEach((method) => {
    const original = rootStorage[method].bind(rootStorage) as (...args: any[]) => any
    ;(rootStorage as any)[method] = (...args: any[]) => {
      const key = typeof args[0] === 'string' ? args[0] : ''
      const namespace = key.split(':')[0] || 'storage'
      return Sentry.startSpan({ name: `${namespace}.${method}`, op: 'db' }, () => original(...args))
    }
  })
}
