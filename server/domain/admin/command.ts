import {
  isBilledMonth,
  monthOf,
  monthStart,
  newPremiumIn,
  premiumBreakdown,
  previousMonthOf,
} from '~/domain/admin/business-rules'
import * as repository from '~/domain/admin/infrastructure/repository'
import type {
  AdminMetricsProjection,
  AiStepUsage,
  MonthCosts,
  MonthSessions,
  Revenue,
} from '~/domain/admin/types'
import { EntitlementQuery } from '~/domain/entitlement/query'
import { Count, Day, Eur } from '~/domain/shared/primitives'
import type { Month } from '~/domain/shared/types'
import { UserQuery } from '~/domain/user/query'
import { AppStoreConnect } from '~/system/appstore-connect'
import { GcpBilling } from '~/system/gcp-billing'
import { GoogleAnalytics } from '~/system/google-analytics'
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

  // The daily job behind the admin screen: count the accounts and who joined
  // this month, work out who is Premium and who subscribed this month, ask Apple
  // what the month sold, the billing export what each day cost and GA4 how many
  // sessions each day had, and write it all as the `current` projection the
  // GraphQL view reads.
  export const refreshMetrics = async (): Promise<AdminMetricsProjection> => {
    const now = new Date()
    const month = monthOf(now)
    const [totalUsers, newUsers, entitlements, previous] = await Promise.all([
      UserQuery.total(),
      UserQuery.joinedSince(monthStart(month)),
      EntitlementQuery.all(),
      repository.findProjection(),
    ])
    // The external sources are independent and all best-effort: missing config
    // or a failing API keeps the last stored figure rather than failing the
    // whole refresh or erasing what was known.
    const [revenue, costs, sessions] = await Promise.all([
      revenueOf(month, previous?.revenue),
      costsOf(month, previous?.costs),
      sessionsOf(month, now, previous?.sessions),
    ])
    return repository.saveProjection({
      totalUsers,
      newUsers,
      premium: premiumBreakdown(entitlements, now),
      newPremium: newPremiumIn(entitlements, month),
      revenue,
      costs,
      sessions,
      refreshedAt: now,
    })
  }
}

// A stored figure only stands in for the month it was measured in: on the 1st,
// last month's days are not this month's.
const ofMonth = <T extends { month: Month }>(month: Month, last: T | undefined) =>
  last?.month === month ? last : undefined

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

// The month's bill day by day, and last month's total when the export holds the
// whole of it: before the first billed month it would be half a bill, so there
// is no comparison rather than a misleading one.
const costsOf = async (month: Month, last: MonthCosts | undefined) => {
  try {
    const days = await GcpBilling.dailyCosts(month)
    if (!days) return ofMonth(month, last)
    const previousMonth = previousMonthOf(month)
    const previousDays = isBilledMonth(previousMonth)
      ? await GcpBilling.dailyCosts(previousMonth)
      : undefined
    const previousMonthEur = previousDays?.reduce(
      (total, day) => total + day.geminiEur + day.infraEur,
      0,
    )
    return {
      month,
      days: days.map((day) => ({
        day: Day(day.day),
        geminiEur: Eur(day.geminiEur),
        infraEur: Eur(day.infraEur),
      })),
      ...(previousMonthEur !== undefined ? { previousMonthEur: Eur(previousMonthEur) } : {}),
    } satisfies MonthCosts
  } catch (error) {
    logger.error('GCP billing refresh failed, keeping the last figure', error)
    return ofMonth(month, last)
  }
}

const sessionsOf = async (month: Month, now: Date, last: MonthSessions | undefined) => {
  try {
    const days = await GoogleAnalytics.dailySessions(`${month}-01`, now.toISOString().slice(0, 10))
    if (!days) return ofMonth(month, last)
    return {
      month,
      days: days.map((day) => ({ day: Day(day.day), sessions: Count(day.sessions) })),
    } satisfies MonthSessions
  } catch (error) {
    logger.error('GA4 sessions refresh failed, keeping the last figure', error)
    return ofMonth(month, last)
  }
}
