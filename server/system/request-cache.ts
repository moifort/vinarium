export const memoizedPerRequest = <T>(key: string, fn: () => T): T => {
  try {
    const event = useEvent()
    if (!event.context._queryCache) event.context._queryCache = {}
    const cache = event.context._queryCache as Record<string, T>
    if (!(key in cache)) cache[key] = fn()
    return cache[key]
  } catch {
    return fn()
  }
}

export const evictFromRequestCache = (key: string) => {
  try {
    const event = useEvent()
    if (event.context._queryCache)
      delete (event.context._queryCache as Record<string, unknown>)[key]
  } catch {}
}
