import { keyBy, range } from 'lodash-es'
import { CellarCol, CellarRow } from '~/domain/cellar/primitives'
import * as _repository from '~/domain/cellar/repository'
import type { CellarBottle, CellarBottleView } from '~/domain/cellar/types'
import * as _wineRepository from '~/domain/wine/repository'
import type { WineId } from '~/domain/wine/types'
import { traced, tracedModule } from '~/system/sentry/tracing'

const repository = tracedModule('cellar', 'db', _repository)
const wineRepository = tracedModule('wine', 'db', _wineRepository)

const CELLAR_SIZE = { rows: 6, cols: 8 }

export namespace CellarQuery {
  export const getAllBottles = traced('CellarQuery.getAllBottles', 'domain.query', async () => {
    const bottles = await repository.findAll()
    const wineMap = keyBy(await wineRepository.findAll(), 'id')
    return bottles.map((bottle) => {
      const wine = wineMap[bottle.wineId]
      if (!wine)
        throw new Error(`Wine ${bottle.wineId} not found for bottle at ${bottle.row},${bottle.col}`)
      return { ...toView(bottle), wine }
    })
  })

  export const getBottleByWineId = traced(
    'CellarQuery.getBottleByWineId',
    'domain.query',
    async (wineId: WineId) => {
      const bottle = await repository.findBy(wineId)
      if (!bottle) return 'not-found' as const
      return toView(bottle)
    },
  )

  export const suggestPosition = traced('CellarQuery.suggestPosition', 'domain.query', async () => {
    const allBottles = await repository.findAll()
    const result = suggest(allBottles)
    if (typeof result === 'string') return result
    return {
      row: result.row,
      col: result.col,
      rowLabel: CellarRow.toLabel(result.row),
      colLabel: CellarCol.toLabel(result.col),
    }
  })

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
