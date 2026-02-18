import { sortBy } from 'lodash-es'
import * as repository from '~/domain/journal/repository'
import type { JournalEntry, JournalEventView } from '~/domain/journal/types'
import { WineQuery } from '~/domain/wine/query'
import type { WineId } from '~/domain/wine/types'

export namespace JournalQuery {
  export const getAll = async () => {
    const entries = await repository.findAll()
    const views = await Promise.all(entries.map(toView))
    return sortBy(views, ({ date }) => -new Date(date).getTime())
  }

  export const getAllByWineId = async (wineId: WineId) => {
    const entries = await repository.findByWineId(wineId)
    const views = await Promise.all(entries.map(toView))
    return sortBy(views, ({ date }) => -new Date(date).getTime())
  }

  const toView = async (entry: JournalEntry): Promise<JournalEventView> => {
    const wine = await WineQuery.getById(entry.wineId)
    if (wine === 'not-found') throw new Error(`Wine not found: ${entry.wineId}`)
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
