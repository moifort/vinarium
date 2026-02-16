import { CellarCommand } from '~/cellar/command'
import { CellarCol, CellarRow } from '~/cellar/primitives'
import { WineId } from '~/wine/primitives'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'Body is required' })

  const wineId = WineId(body.wineId)
  const row = CellarRow(body.row)
  const col = CellarCol(body.col)

  const entry = await CellarCommand.placeWine(wineId, row, col)
  return { status: 201, data: entry }
})
