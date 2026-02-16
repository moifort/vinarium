import { CellarGrid } from '~/cellar-grid/index'
import { CellarHistory } from '~/cellar-history/index'
import type { CellarCol, CellarEntry, CellarRow } from '~/cellar/types'
import { Wines } from '~/wine/index'
import type { WineId } from '~/wine/types'

export namespace Cellar {
  export const getAllEntries = async () => {
    const storage = useStorage('cellar')
    const keys = await storage.getKeys('entries')
    // biome-ignore lint/style/noNonNullAssertion: keys from storage always exist
    return Promise.all(keys.map(async (key) => (await storage.getItem<CellarEntry>(key))!))
  }

  export const getEntryByWineId = async (wineId: WineId) => {
    const storage = useStorage('cellar')
    return storage.getItem<CellarEntry>(`entries:${wineId}`)
  }

  export const placeWine = async (wineId: WineId, row: CellarRow, col: CellarCol) => {
    const wine = await Wines.getById(wineId)
    if (wine === 'not-found') return 'wine-not-found' as const
    const existing = await getEntryByWineId(wineId)
    if (existing) return 'already-placed' as const
    const allEntries = await getAllEntries()
    if (CellarGrid.isPositionTaken(allEntries, row, col)) return 'position-taken' as const
    const now = new Date()
    const entry: CellarEntry = { wineId, row, col, createdAt: now, updatedAt: now }
    await useStorage('cellar').setItem<CellarEntry>(`entries:${wineId}`, entry)
    return entry
  }

  export const removeWine = async (wineId: WineId) => {
    const storage = useStorage('cellar')
    const existing = await getEntryByWineId(wineId)
    if (!existing) return 'not-in-cellar' as const
    await CellarHistory.create({
      wineId: existing.wineId,
      row: existing.row,
      col: existing.col,
      dateIn: existing.createdAt,
      dateOut: new Date(),
    })
    await storage.removeItem(`entries:${wineId}`)
    return
  }

  export const suggestPosition = async (wineId: WineId) => {
    const allEntries = await getAllEntries()
    return CellarGrid.suggest(wineId, allEntries)
  }

  export const getGrid = async () => {
    const allEntries = await getAllEntries()
    return CellarGrid.get(allEntries)
  }
}
