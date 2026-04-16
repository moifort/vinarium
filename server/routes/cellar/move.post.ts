import { CellarCommand } from '~/domain/cellar/command'
import { CellarCol, CellarRow } from '~/domain/cellar/primitives'
import { WineId } from '~/domain/wine/primitives'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'Body is required' })
  const wineId = WineId(body.wineId)
  const rowValue = typeof body.row === 'string' ? body.row.charCodeAt(0) - 65 : body.row
  const colValue = typeof body.col === 'number' ? body.col - 1 : body.col
  const row = CellarRow(rowValue)
  const col = CellarCol(colValue)
  const result = await CellarCommand.moveBottle(wineId, row, col)
  if (result === 'not-in-cellar')
    throw createError({ statusCode: 404, statusMessage: 'Bottle not in cellar' })
  return { status: 200, data: result }
})
