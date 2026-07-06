import { keyBy, sortBy, uniq } from 'lodash-es'
import { wineDetails } from '~/domain/beverage/business-rules'
import { BeverageQuery } from '~/domain/beverage/query'
import type { Beverage, BeverageId } from '~/domain/beverage/types'
import { CellarCol, CellarRow } from '~/domain/cellar/primitives'
import * as repository from '~/domain/journal/infrastructure/repository'
import type { JournalEntry, JournalEventView } from '~/domain/journal/types'
import type { UserId } from '~/domain/shared/types'

export namespace JournalQuery {
  export const all = async (userId: UserId) => {
    const [entries, wines] = await Promise.all([
      repository.findAllByUser(userId),
      BeverageQuery.findAll(userId),
    ])
    const beverageMap = keyBy(wines, ({ id }) => id)
    return sortBy(
      entries.map((entry) => toView(entry, beverageMap)),
      ({ date }) => -new Date(date).getTime(),
    )
  }

  // One page of journal events (offset-based). Loads only the page's wines by id.
  export const page = async (
    userId: UserId,
    { limit, offset }: { limit: number; offset: number },
  ) => {
    const { entries, hasMore } = await repository.findPage(userId, { limit, offset })
    const wines = await BeverageQuery.byBeverageIds(
      userId,
      uniq(entries.map(({ beverageId }) => beverageId)),
    )
    const beverageMap = keyBy(wines, ({ id }) => id)
    const items = entries
      .filter(({ beverageId }) => beverageMap[beverageId])
      .map((entry) => toView(entry, beverageMap))
    return { items, hasMore }
  }

  // Raw entries for a page of wines, batched (for the per-request history loader).
  export const entriesByBeverageIds = async (userId: UserId, beverageIds: BeverageId[]) =>
    repository.findByBeverageIds(userId, beverageIds)

  // Raw journal entries (no wine enrichment) — the read half of an account export.
  export const allEntries = async (userId: UserId) => repository.findAllByUser(userId)

  // A wine's cellar history as displayable events, most recent first. Pure
  // mapping: the entries come from the batched loader, the wine from the parent.
  export const historyOf = (wine: Beverage, entries: JournalEntry[]) => {
    const beverageMap = keyBy([wine], ({ id }) => id)
    return sortBy(
      entries.map((entry) => toView(entry, beverageMap)),
      ({ date }) => -new Date(date).getTime(),
    )
  }

  const toView = (entry: JournalEntry, beverageMap: Record<string, Beverage>): JournalEventView => {
    const wine = beverageMap[entry.beverageId]
    if (!wine) throw new Error(`Beverage not found: ${entry.beverageId}`)
    return {
      type: entry.type,
      date: entry.date,
      beverageId: entry.beverageId,
      beverageName: wine.name,
      wineBeverageType: wine.beverageType,
      wineColor: wineDetails(wine)?.color,
      position: `${CellarRow.toLabel(entry.row)}${CellarCol.toLabel(entry.col)}`,
    }
  }
}
