import type { UserLogEntry } from '~/user-log/types'
import type { WineId } from '~/wine/types'

export namespace UserLog {
  export const create = async (entry: UserLogEntry) => {
    const storage = useStorage('user-log')
    await storage.setItem<UserLogEntry>(`entries:${entry.wineId}`, entry)
    return entry
  }

  export const getByWineId = async (wineId: WineId) => {
    const storage = useStorage('user-log')
    return storage.getItem<UserLogEntry>(`entries:${wineId}`)
  }
}
