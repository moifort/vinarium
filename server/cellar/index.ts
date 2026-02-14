import {
  CellarCols,
  CellarRows,
  colToIndex,
  indexToCol,
  indexToRow,
  rowToIndex,
} from '~/cellar/primitives'
import type { CellarCol, CellarConfig, CellarEntry, CellarRow, CellarSuggestion, Rating } from '~/cellar/types'
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

  export const suggestPosition = async (wineId: WineId): Promise<CellarSuggestion | 'wine-not-found' | 'cellar-full'> => {
    const wine = await Wines.getById(wineId)
    if (wine === 'not-found') return 'wine-not-found' as const

    const cfg = await getConfig()
    const activeEntries = await getActiveEntries()

    const occupied = new Set(activeEntries.map((e) => `${rowToIndex(e.row)},${colToIndex(e.col)}`))

    // Find cells with same-color wines
    const sameColorCells: [number, number][] = []
    for (const entry of activeEntries) {
      const entryWine = await Wines.getById(entry.wineId)
      if (entryWine !== 'not-found' && entryWine.color === wine.color) {
        sameColorCells.push([rowToIndex(entry.row), colToIndex(entry.col)])
      }
    }

    // Find nearest empty cell adjacent to same-color cluster
    if (sameColorCells.length > 0) {
      const directions = [[-1, 0], [1, 0], [0, -1], [0, 1]]
      // BFS from same-color cells
      const queue: [number, number][] = [...sameColorCells]
      const visited = new Set(sameColorCells.map(([r, c]) => `${r},${c}`))

      while (queue.length > 0) {
        const [r, c] = queue.shift()!
        for (const [dr, dc] of directions) {
          const nr = r + dr
          const nc = c + dc
          const key = `${nr},${nc}`
          if (nr >= 0 && nr < cfg.rows && nc >= 0 && nc < cfg.cols && !visited.has(key)) {
            visited.add(key)
            if (!occupied.has(key)) {
              return { row: indexToRow(nr), col: indexToCol(nc) }
            }
            queue.push([nr, nc])
          }
        }
      }
    }

    // No same-color wines or no adjacent space: return first empty cell
    for (let r = 0; r < cfg.rows; r++) {
      for (let c = 0; c < cfg.cols; c++) {
        if (!occupied.has(`${r},${c}`)) {
          return { row: indexToRow(r), col: indexToCol(c) }
        }
      }
    }

    return 'cellar-full' as const
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
