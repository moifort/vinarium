import { Finance } from '~/finance/index'

export default defineEventHandler(async () => {
  const summary = await Finance.getSummary()
  return { status: 200, data: summary }
})
