import { CellarCommand } from '~/cellar/command'
import { CellarCol, CellarRow } from '~/cellar/primitives'
import { WineId } from '~/wine/primitives'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'Body is required' })

  const wineId = WineId(body.wineId)
  const row = CellarRow(body.row)
  const col = CellarCol(body.col)

  const result = await CellarCommand.placeWine(wineId, row, col)
  if (result === 'wine-not-found')
    throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  if (result === 'already-placed')
    throw createError({ statusCode: 409, statusMessage: 'Wine already placed in cellar' })
  if (result === 'position-taken')
    throw createError({ statusCode: 409, statusMessage: 'Position already taken' })
  return { status: 201, data: result }
})
