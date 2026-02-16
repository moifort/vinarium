import { Cellar } from '~/cellar/index'

export default defineEventHandler(async () => {
  const config = await Cellar.getConfig()
  return { status: 200, data: config }
})
