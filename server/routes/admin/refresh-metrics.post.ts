import { AdminCommand } from '~/domain/admin/command'

// Refreshes the admin metrics projection (users, subscribers, revenue, GCP
// bill). Called daily by Cloud Scheduler; /admin/* is Bearer-admin-token gated
// by the auth middleware.
export default defineEventHandler(async () => {
  const projection = await AdminCommand.refreshMetrics()
  return { status: 200, data: projection }
})
