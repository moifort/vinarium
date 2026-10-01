import { range } from 'lodash-es'
import type { CellarBottle, CellarCol, CellarId, CellarRow } from '~/domain/cellar/types'

// The cellar a bottle actually stands in. A bottle names its cellar, but that
// name only holds within the household that owns the cellar: a bottle placed
// before there could be several cellars names none, and one whose owner has
// since joined or left a household names a cellar the new household does not
// hold. Both stand in the primary cellar — exactly where a bottle followed its
// owner before cellars had names, so nothing moves and nothing is stranded.
export const effectiveCellarId = (
  bottle: CellarBottle,
  cellarIds: ReadonlySet<CellarId>,
  primaryId: CellarId,
): CellarId =>
  bottle.cellarId !== undefined && cellarIds.has(bottle.cellarId) ? bottle.cellarId : primaryId

// The first empty slot of a grid, reading row by row from the top left.
export const firstFreeSlot = (
  bottles: Pick<CellarBottle, 'row' | 'col'>[],
  rows: number,
  cols: number,
): { row: number; col: number } | undefined => {
  const occupied = new Set(bottles.map(({ row, col }) => `${row},${col}`))
  return range(rows)
    .flatMap((row) => range(cols).map((col) => ({ row, col })))
    .find(({ row, col }) => !occupied.has(`${row},${col}`))
}

export const isOutsideGrid = (
  { rows, cols }: { rows: number; cols: number },
  row: CellarRow,
  col: CellarCol,
) => row >= rows || col >= cols
