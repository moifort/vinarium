import { CellarLogQuery } from '~/cellar-log/query'

export default defineEventHandler(async () => {
  const history = await CellarLogQuery.getAll()
  return { status: 200, data: history }
})
