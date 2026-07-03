import { keyBy, sortBy } from 'lodash-es'
import { CellarCol, CellarRow } from '~/domain/cellar/primitives'
import * as repository from '~/domain/journal/infrastructure/repository'
import type { JournalEntry, JournalEventView } from '~/domain/journal/types'
import type { UserId } from '~/domain/shared/types'
import { WineQuery } from '~/domain/wine/query'
import type { Wine, WineId } from '~/domain/wine/types'

export namespace JournalQuery {
  // preloadedWines lets callers that already fetched the user's wines (dashboard)
  // skip the redundant collection read.
  export const getAll = async (userId: UserId, preloadedWines?: Wine[] | Promise<Wine[]>) => {
    const [entries, wines] = await Promise.all([
      repository.findAllByUser(userId),
      preloadedWines ?? WineQuery.findAll(userId),
    ])
    const wineMap = keyBy(wines, ({ id }) => id)
    return sortBy(
      entries.map((entry) => toView(entry, wineMap)),
      ({ date }) => -new Date(date).getTime(),
    )
  }

  export const getAllByWineId = async (
    userId: UserId,
    wine: Pick<Wine, 'id' | 'name' | 'beverageType' | 'color'>,
  ) => {
    const entries = await repository.findByWineId(userId, wine.id)
    const wineMap = keyBy([wine], ({ id }) => id)
    return sortBy(
      entries.map((entry) => toView(entry, wineMap)),
      ({ date }) => -new Date(date).getTime(),
    )
  }

  export const getCellarDates = async (userId: UserId, wineId: WineId) => {
    const entries = await repository.findByWineId(userId, wineId)
    const entryIn = entries.find((entry) => entry.type === 'in')
    if (!entryIn) return 'not-found' as const
    const entryOut = entries.find((entry) => entry.type === 'out')
    return {
      wineId,
      dateIn: entryIn.date,
      dateOut: entryOut?.date,
      row: entryIn.row,
      col: entryIn.col,
    }
  }

  const toView = (
    entry: JournalEntry,
    wineMap: Record<string, Pick<Wine, 'name' | 'beverageType' | 'color'>>,
  ): JournalEventView => {
    const wine = wineMap[entry.wineId]
    if (!wine) throw new Error(`Wine not found: ${entry.wineId}`)
    return {
      type: entry.type,
      date: entry.date,
      wineId: entry.wineId,
      wineName: wine.name,
      wineBeverageType: wine.beverageType,
      wineColor: wine.color,
      position: `${CellarRow.toLabel(entry.row)}${CellarCol.toLabel(entry.col)}`,
    }
  }
}
