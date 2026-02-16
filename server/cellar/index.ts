import { range, sortBy } from 'lodash-es'
import {
  CellarCols,
  CellarRows,
  colToIndex,
  indexToCol,
  indexToRow,
  rowToIndex,
} from '~/cellar/primitives'
import type { CellarCol, CellarConfig, CellarEntry, CellarRow, Rating } from '~/cellar/types'
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
    // biome-ignore lint/style/noNonNullAssertion: is not possible that an entry is not found
    return Promise.all(keys.map(async (key) => (await storage.getItem<CellarEntry>(key))!))
  }

  export const getActiveEntries = async () => {
    const entries = await getAllEntries()
    return entries.filter((entry) => !entry.dateOut)
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
    if (activeEntries.some((entry) => entry.row === row && entry.col === col))
      return 'position-taken' as const
    const entry: CellarEntry = { wineId, row, col, dateIn: new Date() }
    await useStorage('cellar').setItem<CellarEntry>(`entries:${wineId}`, entry)
    return entry
  }

  export const removeWine = async (
    wineId: WineId,
    consumption?: { consumedDate?: Date; rating?: Rating; tastingNotes?: string },
  ) => {
    const storage = useStorage('cellar')
    const existing = await getEntryByWineId(wineId)
    if (!existing || existing.dateOut) return 'not-in-cellar' as const
    const updated: CellarEntry = {
      ...existing,
      dateOut: new Date(),
      consumedDate: consumption?.consumedDate,
      rating: consumption?.rating,
      tastingNotes: consumption?.tastingNotes,
    }
    await storage.setItem<CellarEntry>(`entries:${wineId}`, updated)
    return updated
  }

  export const suggestPosition = async (wineId: WineId) => {
    const wine = await Wines.getById(wineId)
    if (wine === 'not-found') return 'wine-not-found' as const
    const config = await getConfig()
    const activeEntries = await getActiveEntries()
    const occupied = activeEntries.map(
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
    const activeEntries = await getActiveEntries()

    const grid: { position: string; wine?: Wine }[][] = Array.from(
      { length: config.rows },
      (_, rowIdx) =>
        Array.from({ length: config.cols }, (_, colIdx) => ({
          position: `${indexToRow(rowIdx)}${indexToCol(colIdx)}`,
        })),
    )

    await Promise.all(
      activeEntries
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

  export const getHistory = async () => {
    const allEntries = await getAllEntries()

    const events = await Promise.all(
      allEntries.flatMap(async (entry) => {
        const wine = await Wines.getById(entry.wineId)
        const wineName = wine !== 'not-found' ? (wine.name as string) : 'Vin inconnu'
        const wineColor = wine !== 'not-found' ? wine.color : 'red'
        const position = `${entry.row}${entry.col}`

        const base = {
          wineId: entry.wineId as string,
          wineName,
          wineColor,
          position,
          rating: undefined as number | undefined,
          tastingNotes: undefined as string | undefined,
        }
        const entryEvent = { ...base, type: 'entry' as const, date: entry.dateIn }

        if (!entry.dateOut) return [entryEvent]

        return [
          entryEvent,
          {
            ...base,
            type: 'exit' as const,
            date: entry.dateOut,
            rating: entry.rating as number | undefined,
            tastingNotes: entry.tastingNotes,
          },
        ]
      }),
    )

    return sortBy(events.flat(), (event) => -new Date(event.date).getTime())
  }
}
