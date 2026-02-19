import { JournalQuery } from '~/domain/journal/query'

export default defineEventHandler(async () => {
  const history = await JournalQuery.getAll()
  return { status: 200, data: history }
})
