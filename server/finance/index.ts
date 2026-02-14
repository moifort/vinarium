import { make } from 'ts-brand'
import { Cellar } from '~/cellar/index'
import type { FinanceSummary, MonthlyReport } from '~/finance/types'
import { Count, Month } from '~/primitives'
import type { Count as CountType, Eur, Month as MonthType, Region } from '~/types'
import { Wines } from '~/wine/index'
import type { WineColor } from '~/wine/types'

const eur = (v: number) => make<Eur>()(v)

const toMonth = (dateStr: string) => Month(dateStr.slice(0, 7))

const currentMonth = () => {
  const now = new Date()
  return Month(`${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`)
}

const monthOffset = (offset: number) => {
  const now = new Date()
  const d = new Date(now.getFullYear(), now.getMonth() - offset, 1)
  return Month(`${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`)
}

const PRICE_RANGES = [
  { range: '0-10€', min: 0, max: 10 },
  { range: '10-20€', min: 10, max: 20 },
  { range: '20-50€', min: 20, max: 50 },
  { range: '50-100€', min: 50, max: 100 },
  { range: '100€+', min: 100, max: Number.POSITIVE_INFINITY },
]

export namespace Finance {
  const winesInCellar = async () => {
    const entries = await Cellar.getActiveEntries()
    const wineIds = new Set(entries.map((e) => String(e.wineId)))
    const allWines = await Wines.list()
    return allWines.filter((w) => wineIds.has(String(w.id)))
  }

  export const analyzeMonth = async (month: MonthType) => {
    const allWines = await Wines.list()
    const monthEnd = `${month}-31`

    // Entries: wines purchased this month
    const entries = allWines.filter((w) => w.purchaseDate && toMonth(w.purchaseDate) === month)
    const entriesValue = entries.reduce((sum, w) => sum + (w.purchasePrice ?? 0), 0)

    // Exits: wines removed from cellar this month (via cellar entries with dateOut in this month)
    const cellarStorage = useStorage('cellar')
    const entryKeys = await cellarStorage.getKeys('entries')
    const cellarEntries = await Promise.all(
      entryKeys.map((key) =>
        cellarStorage.getItem<{ dateOut: string | null; wineId: string }>(key),
      ),
    )
    const exits = cellarEntries
      .filter((e) => e?.dateOut && new Date(e.dateOut).toISOString().slice(0, 7) === month)
      .map((e) => allWines.find((w) => String(w.id) === e?.wineId))
    const exitsCount = exits.length
    const exitsValue = exits.reduce((sum, w) => sum + (w?.purchasePrice ?? 0), 0)

    // Cellar value at end of month
    const inCellarAtMonth = allWines.filter((w) => {
      if (!w.purchaseDate || w.purchaseDate > monthEnd) return false
      return true
    })
    const cellarValue = inCellarAtMonth.reduce((sum, w) => sum + (w.purchasePrice ?? 0), 0)

    const report: MonthlyReport = {
      month,
      cellarValue: eur(cellarValue),
      entriesCount: Count(entries.length),
      entriesValue: eur(entriesValue),
      exitsCount: Count(exitsCount),
      exitsValue: eur(exitsValue),
    }

    return report
  }

  export const saveMonthlyReport = async () => {
    const month = monthOffset(1)
    const report = await analyzeMonth(month)
    const storage = useStorage('finance')
    await storage.setItem<MonthlyReport>(`reports:${month}`, report)
    return report
  }

  export const getSummary = async () => {
    const inCellar = await winesInCellar()

    // Current value
    const currentValue = inCellar.reduce((sum, w) => sum + (w.purchasePrice ?? 0), 0)
    const bottleCount = inCellar.length
    const averagePrice = bottleCount > 0 ? currentValue / bottleCount : 0

    // By color
    const byColor: Partial<Record<WineColor, { count: CountType; value: Eur }>> = {}
    for (const wine of inCellar) {
      const prev = byColor[wine.color] ?? { count: Count(0), value: eur(0) }
      byColor[wine.color] = {
        count: Count(prev.count + 1),
        value: eur(prev.value + (wine.purchasePrice ?? 0)),
      }
    }

    // By region
    const byRegion: Partial<Record<Region, { count: CountType; value: Eur }>> = {}
    for (const wine of inCellar) {
      const region = wine.region
      if (!region) continue
      const prev = byRegion[region] ?? { count: Count(0), value: eur(0) }
      byRegion[region] = {
        count: Count(prev.count + 1),
        value: eur(prev.value + (wine.purchasePrice ?? 0)),
      }
    }

    // By price range
    const byPriceRange = PRICE_RANGES.map(({ range, min, max }) => ({
      range,
      count: Count(
        inCellar.filter((w) => {
          const price = w.purchasePrice ?? 0
          return price >= min && price < max
        }).length,
      ),
    }))

    // Monthly history from persisted reports + current month live
    const financeStorage = useStorage('finance')
    const reportKeys = await financeStorage.getKeys('reports')
    const persisted = await Promise.all(
      reportKeys.map((key) => financeStorage.getItem<MonthlyReport>(key)),
    )
    const liveReport = await analyzeMonth(currentMonth())
    const monthlyHistory = [
      ...persisted.filter((r): r is MonthlyReport => r !== null),
      liveReport,
    ].sort((a, b) => (a.month as string).localeCompare(b.month as string))

    // Trend
    const getValue = (month: MonthType) =>
      monthlyHistory.find((m) => m.month === month)?.cellarValue ?? 0

    const summary: FinanceSummary = {
      currentValue: eur(currentValue),
      bottleCount: Count(bottleCount),
      averagePrice: eur(Math.round(averagePrice * 100) / 100),
      byColor,
      byRegion,
      byPriceRange,
      monthlyHistory,
      trend: {
        lastMonthDelta: eur(currentValue - (getValue(monthOffset(1)) as number)),
        last3MonthsDelta: eur(currentValue - (getValue(monthOffset(3)) as number)),
        last12MonthsDelta: eur(currentValue - (getValue(monthOffset(12)) as number)),
      },
    }

    return summary
  }
}
