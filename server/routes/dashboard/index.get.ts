import { DashboardReadModel } from '~/read-model/dashboard/overview'

export default defineEventHandler(async () => {
  const dashboard = await DashboardReadModel.get()
  return { status: 200, data: dashboard }
})
