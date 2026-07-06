import { keyBy, sortBy, uniq } from 'lodash-es'
import { CellarCol, CellarRow } from '~/domain/cellar/primitives'
import * as repository from '~/domain/journal/infrastructure/repository'
import type { JournalEntry, JournalEventView } from '~/domain/journal/types'
import type { UserId } from '~/domain/shared/types'
import { WineQuery } from '~/domain/wine/query'
import type { Wine, WineId } from '~/domain/wine/types'

export namespace JournalQuery {
  export const getAll = async (userId: UserId) => {
    const [entries, wines] = await Promise.all([
      repository.findAllByUser(userId),
      WineQuery.findAll(userId),
    ])
    const wineMap = keyBy(wines, ({ id }) => id)
    return sortBy(
      entries.map((entry) => toView(entry, wineMap)),
      ({ date }) => -new Date(date).getTime(),
    )
  }

  // One page of journal events (offset-based). Loads only the page's wines by id.
  export const getPage = async (
    userId: UserId,
    { limit, offset }: { limit: number; offset: number },
  ) => {
    const { entries, hasMore } = await repository.findPage(userId, { limit, offset })
    const wines = await WineQuery.getManyByWineIds(
      userId,
      uniq(entries.map(({ wineId }) => wineId)),
    )
    const wineMap = keyBy(wines, ({ id }) => id)
    const items = entries
      .filter(({ wineId }) => wineMap[wineId])
      .map((entry) => toView(entry, wineMap))
    return { items, hasMore }
  }

  // Raw entries for a page of wines, batched (for the per-request history loader).
  export const entriesByWineIds = async (userId: UserId, wineIds: WineId[]) =>
    repository.findByWineIds(userId, wineIds)

  // A wine's cellar history as displayable events, most recent first. Pure
  // mapping: the entries come from the batched loader, the wine from the parent.
  export const historyOf = (
    wine: Pick<Wine, 'id' | 'name' | 'beverageType' | 'color'>,
    entries: JournalEntry[],
  ) => {
    const wineMap = keyBy([wine], ({ id }) => id)
    return sortBy(
      entries.map((entry) => toView(entry, wineMap)),
      ({ date }) => -new Date(date).getTime(),
    )
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
