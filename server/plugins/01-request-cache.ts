/** biome-ignore-all lint/suspicious/noExplicitAny: any is ok here, this is a plugin */
import { evictFromRequestCache, memoizedPerRequest } from '~/system/request-cache'

export default defineNitroPlugin(() => {
  const rootStorage = useStorage()

  const originalGetItem = rootStorage.getItem.bind(rootStorage) as (...args: unknown[]) => unknown
  ;(rootStorage as any).getItem = (...args: unknown[]) =>
    memoizedPerRequest(`getItem:${args[0]}`, () => originalGetItem(...args))

  const originalGetKeys = rootStorage.getKeys.bind(rootStorage) as (...args: unknown[]) => unknown
  ;(rootStorage as any).getKeys = (...args: unknown[]) =>
    memoizedPerRequest(`getKeys:${JSON.stringify(args)}`, () => originalGetKeys(...args))

  const originalSetItem = rootStorage.setItem.bind(rootStorage) as (...args: unknown[]) => unknown
  ;(rootStorage as any).setItem = (...args: unknown[]) => {
    evictFromRequestCache(`getItem:${args[0]}`)
    return originalSetItem(...args)
  }

  const originalRemoveItem = rootStorage.removeItem.bind(rootStorage) as (
    ...args: unknown[]
  ) => unknown
  ;(rootStorage as any).removeItem = (...args: unknown[]) => {
    evictFromRequestCache(`getItem:${args[0]}`)
    return originalRemoveItem(...args)
  }
})
