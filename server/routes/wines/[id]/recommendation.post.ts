import { z } from 'zod'
import { RecommendationCommand } from '~/domain/recommendation/command'
import { RecommenderName } from '~/domain/recommendation/primitives'
import { WineId } from '~/domain/wine/primitives'
import { WineQuery } from '~/domain/wine/query'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const wine = await WineQuery.getById(id)
  if (wine === 'not-found') throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  const body = await readBody(event)
  const comment = body.comment ? z.string().max(1000).parse(body.comment) : undefined
  const recommendation = await RecommendationCommand.create({
    wineId: id,
    recommenderName: body.recommenderName ? RecommenderName(body.recommenderName) : undefined,
    comment,
  })
  return { status: 200, data: recommendation }
})
