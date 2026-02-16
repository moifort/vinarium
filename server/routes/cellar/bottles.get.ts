import { CellarQuery } from '~/cellar/query'

export default defineEventHandler(async () => {
  const bottles = await CellarQuery.getAllBottlesWithWines()
  return { status: 200, data: bottles }
})
