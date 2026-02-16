import { keyBy } from 'lodash-es'
import { TastingQuery } from '~/tasting/query'
import { WineQuery } from '~/wine/query'
import type { SortOrder, WineColor, WineSort, WineStatus } from '~/wine/types'

export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const [wines, tastings] = await Promise.all([
    WineQuery.getAll({
      color: query.color ? (query.color as WineColor) : undefined,
      sort: query.sort ? (query.sort as WineSort) : undefined,
      order: query.order ? (query.order as SortOrder) : undefined,
      status: query.status ? (query.status as WineStatus) : undefined,
    }),
    TastingQuery.getAll(),
  ])
  const ratingMap = keyBy(tastings, 'wineId')
  const data = wines.map((w) => ({ ...w, rating: ratingMap[w.id]?.rating ?? null }))
  return { status: 200, data }
})
