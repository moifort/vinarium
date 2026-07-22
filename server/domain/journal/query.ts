import { keyBy, sortBy, uniq } from 'lodash-es'
import { wineDetails } from '~/domain/beverage/business-rules'
import { BeverageQuery } from '~/domain/beverage/query'
import type { Beverage, BeverageId } from '~/domain/beverage/types'
import { CellarCol, CellarRow } from '~/domain/cellar/primitives'
import { HouseholdQuery } from '~/domain/household/query'
import type { CellarScope } from '~/domain/household/types'
import * as repository from '~/domain/journal/infrastructure/repository'
import type { JournalEntry, JournalEventActor, JournalEventView } from '~/domain/journal/types'
import type { UserId } from '~/domain/shared/types'

// Who moved the bottle, as seen by the viewer: their own movements carry no name
// (the UI omits the badge), a housemate's movement carries theirs.
const actorOf = (entry: JournalEntry, viewerId: UserId, scope: CellarScope): JournalEventActor => {
  const isMine = entry.userId === viewerId
  return {
    userId: entry.userId,
    displayName: isMine ? undefined : scope.displayNames.get(entry.userId),
    isMine,
  }
}

export namespace JournalQuery {
  // The household's most recent exit — the dashboard's "last exit" tile. One
  // limit(1) query plus the wine it names, never a journal scan.
  export const latestExit = async (userId: UserId) => {
    const scope = await HouseholdQuery.cellarScope(userId)
    const entry = await repository.findLatestExitForUsers(scope.memberIds)
    if (!entry) return undefined
    const wines = await BeverageQuery.byBeverageIdsForUsers(scope.memberIds, [entry.beverageId])
    return toViews(
      [entry],
      keyBy(wines, ({ id }) => id),
      userId,
      scope,
    )[0]
  }

  // One page of journal events (offset-based). Loads only the page's wines by id.
  export const page = async (
    userId: UserId,
    { limit, offset }: { limit: number; offset: number },
  ) => {
    const scope = await HouseholdQuery.cellarScope(userId)
    const { entries, hasMore } = await repository.findPageForUsers(scope.memberIds, {
      limit,
      offset,
    })
    const wines = await BeverageQuery.byBeverageIdsForUsers(
      scope.memberIds,
      uniq(entries.map(({ beverageId }) => beverageId)),
    )
    const items = toViews(
      entries,
      keyBy(wines, ({ id }) => id),
      userId,
      scope,
    )
    return { items, hasMore }
  }

  // Raw entries for a page of wines, batched (for the per-request history loader).
  export const entriesByBeverageIds = async (userId: UserId, beverageIds: BeverageId[]) => {
    const scope = await HouseholdQuery.cellarScope(userId)
    return repository.findByBeverageIdsForUsers(scope.memberIds, beverageIds)
  }

  // Raw journal entries (no wine enrichment) — the read half of an account export.
  // Personal by design: an export carries what the user themselves recorded.
  export const allEntries = async (userId: UserId) => repository.findAllByUser(userId)

  // A wine's cellar history as displayable events, most recent first. The entries
  // come from the batched loader and the wine from the parent; only the scope is
  // resolved here, to name the member behind each movement (memoized: no reads).
  export const historyOf = async (viewerId: UserId, wine: Beverage, entries: JournalEntry[]) => {
    const scope = await HouseholdQuery.cellarScope(viewerId)
    const beverageMap = keyBy([wine], ({ id }) => id)
    return sortBy(toViews(entries, beverageMap, viewerId, scope), ({ date }) => -date.getTime())
  }

  // A wine deleted with its journal left behind has no event to show: skip it
  // rather than fail the whole list.
  const toViews = (
    entries: JournalEntry[],
    beverageMap: Record<string, Beverage>,
    viewerId: UserId,
    scope: CellarScope,
  ): JournalEventView[] =>
    entries
      .filter(({ beverageId }) => beverageMap[beverageId])
      .map((entry) => toView(entry, beverageMap[entry.beverageId], viewerId, scope))

  const toView = (
    entry: JournalEntry,
    wine: Beverage,
    viewerId: UserId,
    scope: CellarScope,
  ): JournalEventView => ({
    type: entry.type,
    date: entry.date,
    beverageId: entry.beverageId,
    beverageName: wine.name,
    wineBeverageType: wine.beverageType,
    wineColor: wineDetails(wine)?.color,
    position: `${CellarRow.toLabel(entry.row)}${CellarCol.toLabel(entry.col)}`,
    actor: actorOf(entry, viewerId, scope),
  })
}
