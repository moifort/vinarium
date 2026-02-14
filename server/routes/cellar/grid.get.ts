import { Cellar } from '~/cellar/index'

export default defineEventHandler(async () => {
  const grid = await Cellar.getGrid()
  return { status: 200, data: grid }
})
