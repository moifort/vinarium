import { DashboardQuery } from '~/domain/dashboard/query'

export default defineEventHandler(async () => {
  const dashboard = await DashboardQuery.get()
  throw new Error('test error with sentry-autofix')
  return { status: 200, data: dashboard }
})
