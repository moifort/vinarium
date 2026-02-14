import {
  CellarCols,
  CellarRows,
  colToIndex,
  indexToCol,
  indexToRow,
  rowToIndex,
} from '~/cellar/primitives'
import type { CellarCol, CellarConfig, CellarEntry, CellarRow } from '~/cellar/types'
import { Wines } from '~/wine/index'
import type { Wine, WineId } from '~/wine/types'

const DEFAULT_CONFIG: CellarConfig = {
  rows: CellarRows(10),
  cols: CellarCols(10),
  name: 'Ma cave',
}

export namespace Cellar {
  export const getConfig = async () => {
    const storage = useStorage('cellar')
    const cfg = await storage.getItem<CellarConfig>('config')
    if (!cfg) return DEFAULT_CONFIG
    return cfg
  }

  export const updateConfig = async (data: { rows?: number; cols?: number; name?: string }) => {
    const storage = useStorage('cellar')
    const current = await getConfig()
    const updated: CellarConfig = {
      rows: data.rows != null ? CellarRows(data.rows) : current.rows,
      cols: data.cols != null ? CellarCols(data.cols) : current.cols,
      name: data.name ?? current.name,
    }
    await storage.setItem<CellarConfig>('config', updated)
    return updated
  }

  export const getActiveEntries = async () => {
    const storage = useStorage('cellar')
    const keys = await storage.getKeys('entries')
    const all = await Promise.all(keys.map((key) => storage.getItem<CellarEntry>(key)))
    return all.filter((e): e is CellarEntry => e !== null).filter((e) => !e.dateOut)
  }

  export const getEntryByWineId = async (wineId: WineId) => {
    const storage = useStorage('cellar')
    return storage.getItem<CellarEntry>(`entries:${wineId}`)
  }

  export const placeWine = async (wineId: WineId, row: CellarRow, col: CellarCol) => {
    const wine = await Wines.getById(wineId)
    if (wine === 'not-found') return 'wine-not-found' as const

    const existing = await getEntryByWineId(wineId)
    if (existing && !existing.dateOut) return 'already-placed' as const

    const activeEntries = await getActiveEntries()
    if (activeEntries.some((e) => e.row === row && e.col === col)) return 'position-taken' as const

    const entry: CellarEntry = { wineId, row, col, dateIn: new Date(), dateOut: null }
    await useStorage('cellar').setItem<CellarEntry>(`entries:${wineId}`, entry)
    return entry
  }

  export const removeWine = async (wineId: WineId) => {
    const storage = useStorage('cellar')
    const existing = await getEntryByWineId(wineId)
    if (!existing || existing.dateOut) return 'not-in-cellar' as const
    const updated: CellarEntry = { ...existing, dateOut: new Date() }
    await storage.setItem<CellarEntry>(`entries:${wineId}`, updated)
    return updated
  }

  export const getGrid = async () => {
    const cfg = await getConfig()
    const activeEntries = await getActiveEntries()

    const grid: { position: string; wine: Wine | null }[][] = Array.from(
      { length: cfg.rows },
      (_, rowIdx) =>
        Array.from({ length: cfg.cols }, (_, colIdx) => ({
          position: `${indexToRow(rowIdx)}${indexToCol(colIdx)}`,
          wine: null,
        })),
    )

    await Promise.all(
      activeEntries
        .filter((e) => rowToIndex(e.row) < cfg.rows && colToIndex(e.col) < cfg.cols)
        .map(async (entry) => {
          const wine = await Wines.getById(entry.wineId)
          if (wine !== 'not-found') {
            grid[rowToIndex(entry.row)][colToIndex(entry.col)].wine = wine
          }
        }),
    )

    return grid
  }
}
