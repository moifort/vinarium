import { keyBy, sortBy } from 'lodash-es'
import { BeverageQuery } from '~/domain/beverage/query'
import type { BeverageId } from '~/domain/beverage/types'
import { effectiveCellarId, firstFreeSlot } from '~/domain/cellar/business-rules'
import * as repository from '~/domain/cellar/infrastructure/repository'
import {
  CellarCol,
  CellarCols,
  CellarId,
  CellarRow,
  CellarRows,
  CellarZones,
} from '~/domain/cellar/primitives'
import {
  type Cellar,
  type CellarBottle,
  type CellarBottleOwner,
  type CellarBottleView,
  type CellarId as CellarIdType,
  DEFAULT_CELLAR_SIZE,
  type OwnedBeverage,
  type PlacedBottleWithWine,
  type StoredCellar,
} from '~/domain/cellar/types'
import { HouseholdQuery } from '~/domain/household/query'
import type { CellarScope } from '~/domain/household/types'
import type { UserId } from '~/domain/shared/types'

// A placed bottle projected with its grid labels — the shared cellar view shape,
// used by the queries below and by the placement mutations.
// Generic so a bottle whose cellar is resolved keeps saying so.
export const bottleView = <B extends CellarBottle>(bottle: B): B & CellarBottleView => ({
  ...bottle,
  rowLabel: CellarRow.toLabel(bottle.row),
  colLabel: CellarCol.toLabel(bottle.col),
})

// A bottle's owner as seen by the viewer: their own bottles carry no name (the UI
// omits the badge), a housemate's bottle carries theirs.
const ownerOf = (bottle: CellarBottle, viewerId: UserId, scope: CellarScope): CellarBottleOwner => {
  const isMine = bottle.userId === viewerId
  return {
    userId: bottle.userId,
    displayName: isMine ? undefined : scope.displayNames.get(bottle.userId),
    isMine,
  }
}

// `zones` defaults to 1 for cellars written before the field existed.
const toCellar = (id: string, stored: StoredCellar | null, isPrimary: boolean): Cellar => ({
  id: CellarId(id),
  rows: stored?.rows ?? CellarRows(DEFAULT_CELLAR_SIZE.rows),
  cols: stored?.cols ?? CellarCols(DEFAULT_CELLAR_SIZE.cols),
  zones: stored?.zones ?? CellarZones(DEFAULT_CELLAR_SIZE.zones),
  ...(stored?.name ? { name: stored.name } : {}),
  isPrimary,
})

export namespace CellarQuery {
  // A solo user's own primary cellar id. Deterministic, no membership read.
  export const soloConfigKey = (userId: UserId) => `usr_${userId}`

  // The primary cellar's id, which is also the key every other cellar of the
  // household records: the whole household shares it, a solo user has their own.
  // Resolve this before opening a batch — it reads the membership doc.
  export const configKey = async (userId: UserId) => {
    const membership = await HouseholdQuery.membershipOf(userId)
    return membership ? `hh_${membership.householdId}` : soloConfigKey(userId)
  }

  // Every cellar of the viewer's household, the primary first, then the others in
  // the order they were created. The primary always exists, at the default size
  // until onboarding sets it. Both reads are memoized by the repository, and
  // evicted by its writes, so each placement and each bottle shown resolves its
  // cellar for free and a write is seen by the reads that follow it.
  export const cellars = async (userId: UserId): Promise<Cellar[]> => {
    const key = await configKey(userId)
    const [primary, others] = await Promise.all([
      repository.findConfig(key),
      repository.findSecondary(key),
    ])
    const ordered = sortBy(others, ({ cellar }) => cellar.createdAt?.getTime() ?? 0)
    return [
      toCellar(key, primary, true),
      ...ordered.map(({ id, cellar }) => toCellar(id, cellar, false)),
    ]
  }

  // The cellar a caller designates, or the primary one when they name none — what
  // every client did before there could be several.
  export const byId = async (userId: UserId, cellarId?: CellarIdType) => {
    const all = await cellars(userId)
    const cellar = cellarId === undefined ? all[0] : all.find(({ id }) => id === cellarId)
    return cellar ?? ('not-found' as const)
  }

  // The cellar a bottle stands in, from the viewer's household (see
  // effectiveCellarId).
  export const cellarOf = async (userId: UserId, bottle: CellarBottle) => {
    const all = await cellars(userId)
    return effectiveCellarId(bottle, new Set(all.map(({ id }) => id)), all[0].id)
  }

  // The primary cellar's grid, as it was the only one before.
  export const config = async (userId: UserId) => {
    const { rows, cols, zones } = (await cellars(userId))[0]
    return { rows, cols, zones }
  }

  // A cellar's dimensions and how many of its slots are filled.
  export const info = async (userId: UserId, cellarId?: CellarIdType) => {
    const cellar = await byId(userId, cellarId)
    if (cellar === 'not-found') return 'not-found' as const
    return withUsage(cellar, (await bottlesIn(userId, cellar.id)).length)
  }

  // Every cellar of the household with its usage — the settings list and the
  // cave screen's picker. One scan of the household's bottles serves them all.
  export const overview = async (userId: UserId) => {
    const [all, bottles] = await Promise.all([cellars(userId), placedBottles(userId)])
    const counts = new Map<CellarIdType, number>()
    for (const { cellarId } of bottles) counts.set(cellarId, (counts.get(cellarId) ?? 0) + 1)
    return all.map((cellar) => withUsage(cellar, counts.get(cellar.id) ?? 0))
  }

  // Every bottle standing in any cellar of the household, joined with its wine and
  // tagged with its owner — what the dashboard sums, sorts and dates. The wines are
  // loaded by id (one read per bottle), never through a library scan: a placed
  // bottle's wine always belongs to a household member, so the keyed batch holds.
  export const householdBottlesWithWine = async (
    userId: UserId,
  ): Promise<PlacedBottleWithWine[]> => {
    const [scope, bottles] = await Promise.all([
      HouseholdQuery.cellarScope(userId),
      placedBottles(userId),
    ])
    const wines = await BeverageQuery.byBeverageIdsForUsers(
      scope.memberIds,
      bottles.map(({ beverageId }) => beverageId),
    )
    const beverageMap = keyBy(wines, 'id')
    return bottles.map((bottle) => {
      const wine = beverageMap[bottle.beverageId]
      if (!wine) {
        const at = `${bottle.row},${bottle.col}`
        throw new Error(`Beverage ${bottle.beverageId} not found for bottle at ${at}`)
      }
      return { ...bottleView(bottle), wine, owner: ownerOf(bottle, userId, scope) }
    })
  }

  // Every placed bottle in the viewer's household, whatever its cellar — the wine
  // list and search widen to a housemate's bottle through it. Degenerates to the
  // viewer's own bottles (same memoized scan) when solo.
  export const householdPlacements = async (userId: UserId) => {
    const scope = await HouseholdQuery.cellarScope(userId)
    return (await repository.findAllByUsers(scope.memberIds)).map(bottleView)
  }

  // Raw bottle records (no grid labels) — the read half of an account export.
  export const allRecords = async (userId: UserId) => repository.findAllByUser(userId)

  // One page of a cellar's grid in (row, col) order, each bottle joined with its
  // wine and tagged with its owner. The household's bottles are read whole and
  // carved in memory: which cellar a bottle stands in is only known once its
  // stored cellar is checked against the household's (see effectiveCellarId), so
  // Firestore cannot filter on it. The read is bounded by the grids' capacity, and
  // the app asks for a whole grid in one page anyway.
  export const bottlesPage = async (
    userId: UserId,
    { limit, after, cellarId }: { limit: number; after?: BeverageId; cellarId?: CellarIdType },
  ) => {
    const cellar = await byId(userId, cellarId)
    if (cellar === 'not-found') return 'not-found' as const
    const scope = await HouseholdQuery.cellarScope(userId)
    const inGrid = sortBy(
      await bottlesIn(userId, cellar.id),
      ({ row }) => row,
      ({ col }) => col,
    )
    const start = after ? inGrid.findIndex(({ beverageId }) => beverageId === after) + 1 : 0
    const page = inGrid.slice(start, start + limit)
    const wines = await BeverageQuery.byBeverageIdsForUsers(
      scope.memberIds,
      page.map(({ beverageId }) => beverageId),
    )
    const beverageMap = keyBy(wines, 'id')
    const items = page
      .filter(({ beverageId }) => beverageMap[beverageId])
      .map((bottle) => ({
        ...bottleView(bottle),
        wine: beverageMap[bottle.beverageId],
        owner: ownerOf(bottle, userId, scope),
      }))
    return { items, hasMore: start + limit < inGrid.length }
  }

  // Cellar placements for a page of wines, each read at its owner's exact slot —
  // the shared-cellar loader. A bottle lives under `${owner}_${beverageId}`, so a
  // housemate's wine resolves its placement with no household scan and no waste.
  export const placementsByOwnedBeverages = async (wines: OwnedBeverage[]) =>
    (await repository.findManyByExactIds(wines)).map(bottleView)

  // The household's bottles standing in one cellar, each carrying that cellar.
  export const bottlesIn = async (userId: UserId, cellarId: CellarIdType) =>
    (await placedBottles(userId)).filter((bottle) => bottle.cellarId === cellarId)

  export const suggestPosition = async (userId: UserId, cellarId?: CellarIdType) => {
    const cellar = await byId(userId, cellarId)
    if (cellar === 'not-found') return 'not-found' as const
    const slot = firstFreeSlot(await bottlesIn(userId, cellar.id), cellar.rows, cellar.cols)
    if (!slot) return 'cellar-full' as const
    const row = CellarRow(slot.row)
    const col = CellarCol(slot.col)
    return {
      cellarId: cellar.id,
      row,
      col,
      rowLabel: CellarRow.toLabel(row),
      colLabel: CellarCol.toLabel(col),
    }
  }

  // Every bottle of the household with the cellar it actually stands in, written
  // onto it: past this point a bottle's `cellarId` is never stale nor absent.
  const placedBottles = async (userId: UserId) => {
    const [scope, all] = await Promise.all([HouseholdQuery.cellarScope(userId), cellars(userId)])
    const ids = new Set(all.map(({ id }) => id))
    const bottles = await repository.findAllByUsers(scope.memberIds)
    return bottles.map((bottle) => ({
      ...bottle,
      cellarId: effectiveCellarId(bottle, ids, all[0].id),
    }))
  }

  const withUsage = (cellar: Cellar, placedCount: number) => ({
    ...cellar,
    capacity: cellar.rows * cellar.cols,
    placedCount,
  })
}
