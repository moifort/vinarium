import type { Count, Eur, Month, Region } from '~/types'
import type { WineColor } from '~/wine/types'

export type MonthlyReport = {
  month: Month
  cellarValue: Eur
  entriesCount: Count
  entriesValue: Eur
  exitsCount: Count
  exitsValue: Eur
}

export type FinanceSummary = {
  currentValue: Eur
  bottleCount: Count
  averagePrice: Eur
  byColor: Partial<Record<WineColor, { count: Count; value: Eur }>>
  byRegion: Partial<Record<Region, { count: Count; value: Eur }>>
  byPriceRange: { range: string; count: Count }[]
  monthlyHistory: MonthlyReport[]
  trend: {
    lastMonthDelta: Eur
    last3MonthsDelta: Eur
    last12MonthsDelta: Eur
  }
}
