import { range } from 'lodash-es'
import { CellarCol, CellarCols, CellarRow, CellarRows } from '~/cellar/primitives'
import type { CellarCol as CellarColType, CellarEntry, CellarRow as CellarRowType } from '~/cellar/types'
import { CellarHistory } from '~/cellar-history/index'
import { Wines } from '~/wine/index'
import type { Wine, WineId } from '~/wine/types'

const ROWS = CellarRows(6)
const COLS = CellarCols(8)

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

  export const placeWine = async (wineId: WineId, row: CellarRowType, col: CellarColType) => {
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
    const allEntries = await getAllEntries()
    const occupied = allEntries.map(
      (entry) => `${CellarRow.toIndex(entry.row)},${CellarCol.toIndex(entry.col)}`,
    )
    const firstFree = range(ROWS)
      .flatMap((row) => range(COLS).map((col) => ({ row, col })))
      .find(({ row, col }) => !occupied.includes(`${row},${col}`))
    if (!firstFree) return 'cellar-full' as const
    return { row: CellarRow.fromIndex(firstFree.row), col: CellarCol.fromIndex(firstFree.col) }
  }

  export const getGrid = async () => {
    const allEntries = await getAllEntries()
    const grid: { position: string; wine?: Wine }[][] = Array.from(
      { length: ROWS },
      (_, rowIdx) =>
        Array.from({ length: COLS }, (_, colIdx) => ({
          position: `${CellarRow.fromIndex(rowIdx)}${CellarCol.fromIndex(colIdx)}`,
        })),
    )
    await Promise.all(
      allEntries
        .filter(
          (entry) => CellarRow.toIndex(entry.row) < ROWS && CellarCol.toIndex(entry.col) < COLS,
        )
        .map(async (entry) => {
          const wine = await Wines.getById(entry.wineId)
          if (wine !== 'not-found') {
            grid[CellarRow.toIndex(entry.row)][CellarCol.toIndex(entry.col)].wine = wine
          }
        }),
    )
    return grid
  }
}
