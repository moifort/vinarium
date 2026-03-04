import { afterEach, mock } from 'bun:test'

type StorageItem = { base: string; key: string; value: unknown }

const stores = new Map<string, Map<string, unknown>>()

export const getStore = (namespace: string) => {
  if (!stores.has(namespace)) stores.set(namespace, new Map())
  return stores.get(namespace)!
}

export const clearAllStores = () => {
  for (const store of stores.values()) store.clear()
  stores.clear()
}

const createMockStorage = (namespace: string) => {
  const store = getStore(namespace)
  return {
    getItem: async <T>(key: string) => (store.get(key) as T) ?? null,
    setItem: async <T>(_key: string, value: T) => {
      store.set(_key, value)
    },
    removeItem: async (key: string) => {
      store.delete(key)
    },
    getKeys: async (base?: string) => {
      const keys = [...store.keys()]
      return base ? keys.filter((k) => k.startsWith(`${base}:`)) : keys
    },
    getItems: async <T>(keys: string[]) =>
      keys.map((key) => ({
        base: namespace,
        key,
        value: store.get(key) as T,
      })) as StorageItem[],
  }
}

// @ts-expect-error — global mock for Nitro's useStorage
globalThis.useStorage = (namespace: string) => createMockStorage(namespace)

mock.module('~/system/logger', () => ({
  createLogger: () => ({
    info: () => {},
    warn: () => {},
    error: () => {},
    debug: () => {},
  }),
}))

afterEach(() => {
  clearAllStores()
})
