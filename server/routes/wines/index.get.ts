import { Wines } from '~/wine/index'
import type { WineColor } from '~/wine/types'

export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const color = query.color ? (query.color as WineColor) : undefined
  const wines = await Wines.list(color)
  return { status: 200, data: wines }
})
