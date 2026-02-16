import { range } from 'lodash-es'
import { CellarCol, CellarCols, CellarRow, CellarRows } from '~/cellar/primitives'
import type {
  CellarCol as CellarColType,
  CellarEntry,
  CellarRow as CellarRowType,
} from '~/cellar/types'
import type { GridCell } from '~/cellar-grid/types'
import { Wines } from '~/wine/index'
import type { WineId } from '~/wine/types'

const ROWS = CellarRows(6)
const COLS = CellarCols(8)

export namespace CellarGrid {
  export const isPositionTaken = (entries: CellarEntry[], row: CellarRowType, col: CellarColType) =>
    entries.some((entry) => entry.row === row && entry.col === col)

  export const suggest = async (wineId: WineId, entries: CellarEntry[]) => {
    const wine = await Wines.getById(wineId)
    if (wine === 'not-found') return 'wine-not-found' as const
    const occupied = entries.map(
      (entry) => `${CellarRow.toIndex(entry.row)},${CellarCol.toIndex(entry.col)}`,
    )
    const firstFree = range(ROWS)
      .flatMap((row) => range(COLS).map((col) => ({ row, col })))
      .find(({ row, col }) => !occupied.includes(`${row},${col}`))
    if (!firstFree) return 'cellar-full' as const
    return { row: CellarRow.fromIndex(firstFree.row), col: CellarCol.fromIndex(firstFree.col) }
  }

  export const get = async (entries: CellarEntry[]) => {
    const grid: GridCell[][] = Array.from({ length: ROWS }, (_, rowIdx) =>
      Array.from({ length: COLS }, (_, colIdx) => ({
        position: `${CellarRow.fromIndex(rowIdx)}${CellarCol.fromIndex(colIdx)}`,
      })),
    )
    await Promise.all(
      entries
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
