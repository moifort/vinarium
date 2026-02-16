import { WineQuery } from '~/wine/query'
import type { SortOrder, WineColor, WineSort, WineStatus } from '~/wine/types'

export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const wines = await WineQuery.getAll({
    color: query.color ? (query.color as WineColor) : undefined,
    sort: query.sort ? (query.sort as WineSort) : undefined,
    order: query.order ? (query.order as SortOrder) : undefined,
    status: query.status ? (query.status as WineStatus) : undefined,
  })
  return { status: 200, data: wines }
})
