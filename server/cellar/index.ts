import { range } from 'lodash-es'
import {
  CellarCols,
  CellarRows,
  colToIndex,
  indexToCol,
  indexToRow,
  rowToIndex,
} from '~/cellar/primitives'
import type { CellarCol, CellarConfig, CellarEntry, CellarRow } from '~/cellar/types'
import { CellarHistory } from '~/cellar-history/index'
import { Wines } from '~/wine/index'
import type { Wine, WineId } from '~/wine/types'

const DEFAULT_CONFIG: CellarConfig = {
  rows: CellarRows(6),
  cols: CellarCols(8),
  name: 'DE DIETRICH DUW46DFB',
}

export namespace Cellar {
  export const getConfig = async () => {
    const storage = useStorage('cellar')
    const config = await storage.getItem<CellarConfig>('config')
    if (!config) return DEFAULT_CONFIG
    return config
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
    if (allEntries.some((entry) => entry.row === row && entry.col === col))
      return 'position-taken' as const
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
    return 'ok' as const
  }

  export const suggestPosition = async (wineId: WineId) => {
    const wine = await Wines.getById(wineId)
    if (wine === 'not-found') return 'wine-not-found' as const
    const config = await getConfig()
    const allEntries = await getAllEntries()
    const occupied = allEntries.map(
      (entry) => `${rowToIndex(entry.row)},${colToIndex(entry.col)}`,
    )
    const firstFree = range(config.rows)
      .flatMap((row) => range(config.cols).map((col) => ({ row, col })))
      .find(({ row, col }) => !occupied.includes(`${row},${col}`))
    if (!firstFree) return 'cellar-full' as const
    return { row: indexToRow(firstFree.row), col: indexToCol(firstFree.col) }
  }

  export const getGrid = async () => {
    const config = await getConfig()
    const allEntries = await getAllEntries()
    const grid: { position: string; wine?: Wine }[][] = Array.from(
      { length: config.rows },
      (_, rowIdx) =>
        Array.from({ length: config.cols }, (_, colIdx) => ({
          position: `${indexToRow(rowIdx)}${indexToCol(colIdx)}`,
        })),
    )
    await Promise.all(
      allEntries
        .filter(
          (entry) => rowToIndex(entry.row) < config.rows && colToIndex(entry.col) < config.cols,
        )
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
