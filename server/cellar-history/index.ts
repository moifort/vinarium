import { sortBy } from 'lodash-es'
import { Cellar } from '~/cellar/index'
import type { CellarHistoryEntry, CellarHistoryEvent } from '~/cellar-history/types'
import { UserLog } from '~/user-log/index'
import { Wines } from '~/wine/index'
import type { WineId } from '~/wine/types'

export namespace CellarHistory {
  export const create = async (entry: CellarHistoryEntry) => {
    const storage = useStorage('cellar-history')
    await storage.setItem<CellarHistoryEntry>(`entries:${entry.wineId}`, entry)
    return entry
  }

  export const getByWineId = async (wineId: WineId) => {
    const storage = useStorage('cellar-history')
    return storage.getItem<CellarHistoryEntry>(`entries:${wineId}`)
  }

  const getAllEntries = async () => {
    const storage = useStorage('cellar-history')
    const keys = await storage.getKeys('entries')
    // biome-ignore lint/style/noNonNullAssertion: keys from storage always exist
    return Promise.all(keys.map(async (key) => (await storage.getItem<CellarHistoryEntry>(key))!))
  }

  export const list = async () => {
    const activeEntries = await Cellar.getAllEntries()
    const historyEntries = await getAllEntries()

    const events = await Promise.all([
      ...activeEntries.map(async (entry) => {
        const wine = await Wines.getById(entry.wineId)
        const wineName = wine !== 'not-found' ? (wine.name as string) : 'Vin inconnu'
        const wineColor = wine !== 'not-found' ? wine.color : 'red'
        const event: CellarHistoryEvent = {
          type: 'entry',
          date: entry.createdAt,
          wineId: entry.wineId as string,
          wineName,
          wineColor,
          position: `${entry.row}${entry.col}`,
        }
        return [event]
      }),
      ...historyEntries.map(async (entry) => {
        const wine = await Wines.getById(entry.wineId)
        const wineName = wine !== 'not-found' ? (wine.name as string) : 'Vin inconnu'
        const wineColor = wine !== 'not-found' ? wine.color : 'red'
        const position = `${entry.row}${entry.col}`
        const userLog = await UserLog.getByWineId(entry.wineId)

        const entryEvent: CellarHistoryEvent = {
          type: 'entry',
          date: entry.dateIn,
          wineId: entry.wineId as string,
          wineName,
          wineColor,
          position,
        }
        const exitEvent: CellarHistoryEvent = {
          type: 'exit',
          date: entry.dateOut,
          wineId: entry.wineId as string,
          wineName,
          wineColor,
          position,
          rating: userLog?.rating as number | undefined,
          tastingNotes: userLog?.tastingNotes,
        }
        return [entryEvent, exitEvent]
      }),
    ])

    return sortBy(events.flat(), (event) => -new Date(event.date).getTime())
  }
}
