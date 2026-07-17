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
  // The whole shared journal: a cellar's movements belong to every member, so the
  // events of each one merge here, most recent first.
  export const all = async (userId: UserId) => {
    const scope = await HouseholdQuery.cellarScope(userId)
    const entries = await repository.findAllByUsers(scope.memberIds)
    const beverageMap = await winesOfEntries(userId, scope, entries)
    return sortBy(toViews(entries, beverageMap, userId, scope), ({ date }) => -date.getTime())
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

  // The wines a set of entries points at. The visible set already covers the
  // viewer's library and housemates' in-cellar wines (one memoized scan the
  // dashboard shares); the rest — a housemate's bottle that left the cellar — is
  // read by id, so their exits never drop out of the shared journal.
  const winesOfEntries = async (userId: UserId, scope: CellarScope, entries: JournalEntry[]) => {
    const visible = keyBy(await BeverageQuery.allVisibleTo(userId), ({ id }) => id)
    const missing = uniq(entries.map(({ beverageId }) => beverageId).filter((id) => !visible[id]))
    if (missing.length === 0) return visible
    const extra = await BeverageQuery.byBeverageIdsForUsers(scope.memberIds, missing)
    return { ...visible, ...keyBy(extra, ({ id }) => id) }
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
