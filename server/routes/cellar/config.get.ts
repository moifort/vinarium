import { Cellar } from '~/cellar/index'

export default defineEventHandler(async () => {
  const cfg = await Cellar.getConfig()
  return { status: 200, data: cfg }
})
