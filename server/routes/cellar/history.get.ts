import { Cellar } from '~/cellar/index'

export default defineEventHandler(async () => {
  const history = await Cellar.getHistory()
  return { status: 200, data: history }
})
