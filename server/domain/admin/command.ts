import { monthOf, premiumBreakdown } from '~/domain/admin/business-rules'
import * as repository from '~/domain/admin/infrastructure/repository'
import type { AdminMetricsProjection, AiStepUsage, InfraUsage, Revenue } from '~/domain/admin/types'
import { EntitlementQuery } from '~/domain/entitlement/query'
import { Eur } from '~/domain/shared/primitives'
import type { Month } from '~/domain/shared/types'
import { UserQuery } from '~/domain/user/query'
import { AppStoreConnect } from '~/system/appstore-connect'
import { GcpBilling } from '~/system/gcp-billing'
import { createLogger } from '~/system/logger'

const logger = createLogger('admin')

export namespace AdminCommand {
  // Fold one scan into the month's cost counters — a single atomic write of
  // increments, called by the scan resolver after the fact. A cache hit counts
  // as a hit and no tokens; a real scan counts once with whatever both Gemini
  // calls reported. The caller treats this as telemetry: a failure here must
  // never fail the scan that produced it.
  export const recordAiUsage = async (usage: {
    cacheHit: boolean
    vision?: AiStepUsage
    enrichment?: AiStepUsage
  }) => {
    await repository.recordUsage(monthOf(new Date()), {
      scans: usage.cacheHit ? 0 : 1,
      cacheHits: usage.cacheHit ? 1 : 0,
      vision: usage.vision,
      enrichment: usage.enrichment,
    })
  }

  // The daily job behind the admin screen: count the accounts, work out who is
  // Premium, ask Apple what the month sold and BigQuery what GCP billed, and
  // write it all as the `current` projection the GraphQL view reads.
  export const refreshMetrics = async (): Promise<AdminMetricsProjection> => {
    const now = new Date()
    const month = monthOf(now)
    const [totalUsers, entitlements, previous] = await Promise.all([
      UserQuery.total(),
      EntitlementQuery.all(),
      repository.findProjection(),
    ])
    // The two external sources are independent and both best-effort: missing
    // config or a failing API keeps the last stored figure rather than failing
    // the whole refresh or erasing what was known.
    const [revenue, infra] = await Promise.all([
      revenueOf(month, previous?.revenue),
      infraOf(month, previous?.infra),
    ])
    return repository.saveProjection({
      totalUsers,
      premium: premiumBreakdown(entitlements, now),
      revenue,
      infra,
      refreshedAt: now,
    })
  }

  const revenueOf = async (month: Month, last: Revenue | undefined) => {
    try {
      const sales = await AppStoreConnect.monthSales(month)
      if (!sales) return last
      return { month, proceedsEur: Eur(sales.proceedsEur), grossEur: Eur(sales.grossEur) }
    } catch (error) {
      logger.error('App Store revenue refresh failed, keeping the last figure', error)
      return last
    }
  }

  const infraOf = async (month: Month, last: InfraUsage | undefined) => {
    try {
      const cost = await GcpBilling.monthCost(month)
      if (cost === undefined) return last
      return { month, gcpCostEur: Eur(cost) }
    } catch (error) {
      logger.error('GCP billing refresh failed, keeping the last figure', error)
      return last
    }
  }
}
