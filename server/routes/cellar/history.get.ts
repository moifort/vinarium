import { CellarHistory } from '~/cellar-history/index'

export default defineEventHandler(async () => {
  const history = await CellarHistory.list()
  return { status: 200, data: history }
})
