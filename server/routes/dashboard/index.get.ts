import { DashboardQuery } from '~/domain/dashboard/query'

export default defineEventHandler(async () => {
  const dashboard = await DashboardQuery.get()
  return { status: 200, data: dashboard }
})
