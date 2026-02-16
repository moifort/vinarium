import { sortBy } from 'lodash-es'
import { CellarCol, CellarRow } from '~/cellar/primitives'
import { CellarQuery } from '~/cellar/query'
import * as repository from '~/cellar-history/repository'
import type { CellarHistoryEntry, CellarHistoryEvent } from '~/cellar-history/types'
import { UserLog } from '~/user-log/index'
import { Wines } from '~/wine/index'
import type { WineId } from '~/wine/types'

export namespace CellarHistory {
  export const create = async (entry: CellarHistoryEntry) => {
    await repository.save(entry)
    return entry
  }

  export const getByWineId = (wineId: WineId) => repository.findBy(wineId)

  export const list = async () => {
    const activeEntries = await CellarQuery.getAllEntries()
    const historyEntries = await repository.findAll()

    const events = await Promise.all([
      ...activeEntries.map(async (entry) => {
        const wine = await Wines.getById(entry.wineId)
        const wineName = wine !== 'not-found' ? (wine.name as string) : 'Vin inconnu'
        const wineColor = wine !== 'not-found' ? wine.color : 'red'
        const event: CellarHistoryEvent = {
          type: 'entry',
          date: entry.createdAt,
          wineId: entry.wineId as string,
          wineName,
          wineColor,
          position: `${entry.rowLabel}${entry.colLabel}`,
        }
        return [event]
      }),
      ...historyEntries.map(async (entry) => {
        const wine = await Wines.getById(entry.wineId)
        const wineName = wine !== 'not-found' ? (wine.name as string) : 'Vin inconnu'
        const wineColor = wine !== 'not-found' ? wine.color : 'red'
        const position = `${CellarRow.toLabel(entry.row)}${CellarCol.toLabel(entry.col)}`
        const userLog = await UserLog.getByWineId(entry.wineId)

        const entryEvent: CellarHistoryEvent = {
          type: 'entry',
          date: entry.dateIn,
          wineId: entry.wineId as string,
          wineName,
          wineColor,
          position,
        }
        if (!entry.dateOut) return [entryEvent]
        const exitEvent: CellarHistoryEvent = {
          type: 'exit',
          date: entry.dateOut,
          wineId: entry.wineId as string,
          wineName,
          wineColor,
          position,
          rating: userLog?.rating as number | undefined,
          tastingNotes: userLog?.tastingNotes,
        }
        return [entryEvent, exitEvent]
      }),
    ])

    return sortBy(events.flat(), (event) => -new Date(event.date).getTime())
  }
}
