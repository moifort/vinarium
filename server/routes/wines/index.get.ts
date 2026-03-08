import { SortOrder, WineColor, WineSort, WineStatus } from '~/domain/wine/primitives'
import { WineListReadModel } from '~/read-model/wine/wine-list'

export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const wines = await WineListReadModel.all({
    color: query.color ? WineColor(query.color) : undefined,
    sort: query.sort ? WineSort(query.sort) : undefined,
    order: query.order ? SortOrder(query.order) : undefined,
    status: query.status ? WineStatus(query.status) : undefined,
  })
  return { status: 200, data: wines }
})
