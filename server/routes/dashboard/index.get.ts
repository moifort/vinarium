import { DashboardQuery } from '~/dashboard/query'

export default defineEventHandler(async () => {
  const dashboard = await DashboardQuery.get()
  return { status: 200, data: dashboard }
})
