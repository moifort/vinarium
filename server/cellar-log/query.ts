import { sortBy } from 'lodash-es'
import * as repository from '~/cellar-log/repository'
import type { CellarLogEntry, CellarLogEventView } from '~/cellar-log/types'
import { UserLog } from '~/user-log/index'
import { Wines } from '~/wine/index'
import type { WineId } from '~/wine/types'

export namespace CellarLogQuery {
  export const list = async () => {
    const entries = await repository.findAll()
    const views = await Promise.all(entries.map(toView))
    return sortBy(views, (event) => -new Date(event.date).getTime())
  }

  export const getByWineId = async (wineId: WineId) => {
    const entries = await repository.findByWineId(wineId)
    const views = await Promise.all(entries.map(toView))
    return sortBy(views, (event) => -new Date(event.date).getTime())
  }

  const toView = async (entry: CellarLogEntry): Promise<CellarLogEventView> => {
    const wine = await Wines.getById(entry.wineId)
    const wineName = wine !== 'not-found' ? (wine.name as string) : 'Vin inconnu'
    const wineColor = wine !== 'not-found' ? wine.color : 'red'
    const position = `${entry.rowLabel}${entry.colLabel}`

    if (entry.type === 'out') {
      const userLog = await UserLog.getByWineId(entry.wineId)
      return {
        type: 'out',
        date: entry.dateOut,
        wineId: entry.wineId as string,
        wineName,
        wineColor,
        position,
        rating: userLog?.rating as number | undefined,
        tastingNotes: userLog?.tastingNotes,
      }
    }

    return {
      type: 'in',
      date: entry.dateIn,
      wineId: entry.wineId as string,
      wineName,
      wineColor,
      position,
    }
  }
}
