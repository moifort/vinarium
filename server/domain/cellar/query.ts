import { keyBy, range } from 'lodash-es'
import * as repository from '~/domain/cellar/infrastructure/repository'
import { CellarCol, CellarRow } from '~/domain/cellar/primitives'
import { CELLAR_SIZE, type CellarBottle, type CellarBottleView } from '~/domain/cellar/types'
import type { UserId } from '~/domain/shared/types'
import { WineQuery } from '~/domain/wine/query'
import type { WineId } from '~/domain/wine/types'

// A placed bottle projected with its grid labels — the shared cellar view shape,
// used by the queries below and by the placement mutations.
export const bottleView = (bottle: CellarBottle): CellarBottleView => ({
  ...bottle,
  rowLabel: CellarRow.toLabel(bottle.row),
  colLabel: CellarCol.toLabel(bottle.col),
})

export namespace CellarQuery {
  export const info = async (userId: UserId) => ({
    rows: CELLAR_SIZE.rows,
    cols: CELLAR_SIZE.cols,
    capacity: CELLAR_SIZE.rows * CELLAR_SIZE.cols,
    // Server-side aggregation: counting never loads the cellar documents.
    placedCount: await repository.countByUser(userId),
  })

  export const bottlesWithWine = async (userId: UserId) => {
    const [bottles, wines] = await Promise.all([
      repository.findAllByUser(userId),
      WineQuery.findAll(userId),
    ])
    const wineMap = keyBy(wines, 'id')
    return bottles.map((bottle) => {
      const wine = wineMap[bottle.wineId]
      if (!wine)
        throw new Error(`Wine ${bottle.wineId} not found for bottle at ${bottle.row},${bottle.col}`)
      return { ...bottleView(bottle), wine }
    })
  }

  export const placements = async (userId: UserId) => {
    const bottles = await repository.findAllByUser(userId)
    return bottles.map(bottleView)
  }

  // Raw bottle records (no grid labels) — the read half of an account export.
  export const allRecords = async (userId: UserId) => repository.findAllByUser(userId)

  // One page of cellar bottles in grid order (row, col) joined with their wine.
  export const bottlesPage = async (
    userId: UserId,
    { limit, after }: { limit: number; after?: WineId },
  ) => {
    const { bottles, hasMore } = await repository.findBottlesPage(userId, { limit, after })
    const wines = await WineQuery.byWineIds(
      userId,
      bottles.map(({ wineId }) => wineId),
    )
    const wineMap = keyBy(wines, 'id')
    const items = bottles
      .filter(({ wineId }) => wineMap[wineId])
      .map((bottle) => ({ ...bottleView(bottle), wine: wineMap[bottle.wineId] }))
    return { items, hasMore }
  }

  // Cellar placements for a page of wines, batch-loaded by id.
  export const placementsByWineIds = async (userId: UserId, wineIds: WineId[]) =>
    (await repository.findManyByWineIds(userId, wineIds)).map(bottleView)

  export const suggestPosition = async (userId: UserId) => {
    const allBottles = await repository.findAllByUser(userId)
    const result = suggest(allBottles)
    if (typeof result === 'string') return result
    return {
      row: result.row,
      col: result.col,
      rowLabel: CellarRow.toLabel(result.row),
      colLabel: CellarCol.toLabel(result.col),
    }
  }

  const suggest = (bottles: CellarBottle[]) => {
    const occupied = bottles.map((bottle) => `${bottle.row},${bottle.col}`)
    const firstFree = range(CELLAR_SIZE.rows)
      .flatMap((row) => range(CELLAR_SIZE.cols).map((col) => ({ row, col })))
      .find(({ row, col }) => !occupied.includes(`${row},${col}`))
    if (!firstFree) return 'cellar-full' as const
    return { row: CellarRow(firstFree.row), col: CellarCol(firstFree.col) }
  }
}
