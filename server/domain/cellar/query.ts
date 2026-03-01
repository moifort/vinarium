import { keyBy, range } from 'lodash-es'
import { CellarCol, CellarRow } from '~/domain/cellar/primitives'
import * as repository from '~/domain/cellar/repository'
import type { CellarBottle, CellarBottleView } from '~/domain/cellar/types'
import { WineQuery } from '~/domain/wine/query'
import type { WineId } from '~/domain/wine/types'

const CELLAR_SIZE = { rows: 6, cols: 8 }

export namespace CellarQuery {
  export const getAllBottles = async () => {
    const bottles = await repository.findAll()
    const wineMap = keyBy(await WineQuery.findAll(), 'id')
    return bottles.map((bottle) => {
      const wine = wineMap[bottle.wineId]
      if (!wine)
        throw new Error(`Wine ${bottle.wineId} not found for bottle at ${bottle.row},${bottle.col}`)
      return { ...toView(bottle), wine }
    })
  }

  export const getBottleByWineId = async (wineId: WineId) => {
    const bottle = await repository.findBy(wineId)
    if (!bottle) return 'not-found' as const
    return toView(bottle)
  }

  export const suggestPosition = async () => {
    const allBottles = await repository.findAll()
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
