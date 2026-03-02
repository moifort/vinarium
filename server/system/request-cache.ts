export const cacheKeys = {
  getItem: (args: unknown[]) => `getItem:${args[0]}`,
  getItems: (args: unknown[]) => `getItems:${JSON.stringify(args)}`,
  getKeys: (args: unknown[]) => `getKeys:${JSON.stringify(args)}`,
}

let _lastHit = false

export const memoizedPerRequest = <T>(key: string, fn: () => T): T => {
  try {
    const event = useEvent()
    if (!event.context._queryCache) event.context._queryCache = {}
    const cache = event.context._queryCache as Record<string, T>
    _lastHit = key in cache
    if (!_lastHit) cache[key] = fn()
    return cache[key]
  } catch {
    _lastHit = false
    return fn()
  }
}

export const wasLastCacheHit = () => _lastHit

export const evictFromRequestCache = (key: string) => {
  try {
    const event = useEvent()
    if (event.context._queryCache)
      delete (event.context._queryCache as Record<string, unknown>)[key]
  } catch {}
}
