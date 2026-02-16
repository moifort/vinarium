import { CellarQuery } from '~/cellar/query'

export default defineEventHandler(async () => {
  const grid = await CellarQuery.getGrid()
  return { status: 200, data: grid }
})
