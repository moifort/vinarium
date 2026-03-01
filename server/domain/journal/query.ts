import { keyBy, sortBy } from 'lodash-es'
import * as repository from '~/domain/journal/repository'
import type { JournalEntry, JournalEventView } from '~/domain/journal/types'
import { WineQuery } from '~/domain/wine/query'
import type { Wine, WineId } from '~/domain/wine/types'

export namespace JournalQuery {
  export const getAll = async () => {
    const [entries, wines] = await Promise.all([repository.findAll(), WineQuery.findAll()])
    const wineMap = keyBy(wines, ({ id }) => id)
    return sortBy(
      entries.map((entry) => toView(entry, wineMap)),
      ({ date }) => -new Date(date).getTime(),
    )
  }

  export const getAllByWineId = async (wine: Pick<Wine, 'id' | 'name' | 'color'>) => {
    const entries = await repository.findByWineId(wine.id)
    const wineMap = keyBy([wine], ({ id }) => id)
    return sortBy(
      entries.map((entry) => toView(entry, wineMap)),
      ({ date }) => -new Date(date).getTime(),
    )
  }

  export const getCellarDates = async (wineId: WineId) => {
    const entries = await repository.findByWineId(wineId)
    const entryIn = entries.find((entry) => entry.type === 'in')
    if (!entryIn) return 'not-found' as const
    const entryOut = entries.find((entry) => entry.type === 'out')
    return {
      wineId,
      dateIn: entryIn.dateIn,
      dateOut: entryOut?.dateOut,
      rowLabel: entryIn.rowLabel,
      colLabel: entryIn.colLabel,
    }
  }

  const toView = (
    entry: JournalEntry,
    wineMap: Record<string, Pick<Wine, 'name' | 'color'>>,
  ): JournalEventView => {
    const wine = wineMap[entry.wineId]
    if (!wine) throw new Error(`Wine not found: ${entry.wineId}`)
    return {
      type: entry.type,
      date: entry.type === 'in' ? entry.dateIn : entry.dateOut,
      wineId: entry.wineId,
      wineName: wine.name,
      wineColor: wine.color,
      position: `${entry.rowLabel}${entry.colLabel}`,
    }
  }
}
