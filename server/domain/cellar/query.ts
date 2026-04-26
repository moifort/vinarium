import { keyBy, range } from 'lodash-es'
import * as repository from '~/domain/cellar/infrastructure/repository'
import { CellarCol, CellarRow } from '~/domain/cellar/primitives'
import { CELLAR_SIZE, type CellarBottle, type CellarBottleView } from '~/domain/cellar/types'
import type { UserId } from '~/domain/shared/types'
import { WineQuery } from '~/domain/wine/query'
import type { WineId } from '~/domain/wine/types'

export namespace CellarQuery {
  export const getCellarInfo = async (userId: UserId) => {
    const bottles = await repository.findAllByUser(userId)
    return {
      rows: CELLAR_SIZE.rows,
      cols: CELLAR_SIZE.cols,
      capacity: CELLAR_SIZE.rows * CELLAR_SIZE.cols,
      placedCount: bottles.length,
    }
  }

  export const getAllBottles = async (userId: UserId) => {
    const [bottles, wines] = await Promise.all([
      repository.findAllByUser(userId),
      WineQuery.findAll(userId),
    ])
    const wineMap = keyBy(wines, 'id')
    return bottles.map((bottle) => {
      const wine = wineMap[bottle.wineId]
      if (!wine)
        throw new Error(`Wine ${bottle.wineId} not found for bottle at ${bottle.row},${bottle.col}`)
      return { ...toView(bottle), wine }
    })
  }

  export const getBottleByWineId = async (userId: UserId, wineId: WineId) => {
    const bottle = await repository.findBy(userId, wineId)
    if (!bottle) return 'not-found' as const
    return toView(bottle)
  }

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

  const toView = (bottle: CellarBottle): CellarBottleView => ({
    ...bottle,
    rowLabel: CellarRow.toLabel(bottle.row),
    colLabel: CellarCol.toLabel(bottle.col),
  })
}
