import { Wines } from '~/wine/index'
import type { WineColor } from '~/wine/types'

export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const wines = await Wines.list({
    color: query.color ? (query.color as WineColor) : undefined,
    sort: query.sort as 'vintage' | 'region' | 'color' | 'price' | 'consumedDate' | undefined,
    order: query.order as 'asc' | 'desc' | undefined,
    status: query.status as 'in-cellar' | 'consumed' | 'all' | undefined,
  })
  return { status: 200, data: wines }
})
