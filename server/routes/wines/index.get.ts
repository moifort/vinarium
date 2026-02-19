import { SortOrder, WineColor, WineSort, WineStatus } from '~/domain/wine/primitives'
import { WineQuery } from '~/domain/wine/query'

export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const wines = await WineQuery.getAll({
    color: query.color ? WineColor(query.color) : undefined,
    sort: query.sort ? WineSort(query.sort) : undefined,
    order: query.order ? SortOrder(query.order) : undefined,
    status: query.status ? WineStatus(query.status) : undefined,
  })
  return { status: 200, data: wines }
})
