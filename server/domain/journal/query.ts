import { keyBy, sortBy } from 'lodash-es'
import * as _repository from '~/domain/journal/repository'
import type { JournalEntry, JournalEventView } from '~/domain/journal/types'
import { WineQuery } from '~/domain/wine/query'
import * as _wineRepository from '~/domain/wine/repository'
import type { Wine, WineId } from '~/domain/wine/types'
import { traced, tracedModule } from '~/system/sentry/tracing'

const repository = tracedModule('journal', 'db', _repository)
const wineRepository = tracedModule('wine', 'db', _wineRepository)

export namespace JournalQuery {
  export const getAll = traced('JournalQuery.getAll', 'domain.query', async () => {
    const [entries, wines] = await Promise.all([repository.findAll(), wineRepository.findAll()])
    const wineMap = keyBy(wines, 'id')
    return sortBy(
      entries.map((entry) => toView(entry, wineMap)),
      ({ date }) => -new Date(date).getTime(),
    )
  })

  export const getAllByWineId = traced(
    'JournalQuery.getAllByWineId',
    'domain.query',
    async (wineId: WineId) => {
      const entries = await repository.findByWineId(wineId)
      const wine = await WineQuery.getById(wineId)
      if (wine === 'not-found') throw new Error(`Wine not found: ${wineId}`)
      const wineMap = keyBy([wine], 'id')
      return sortBy(
        entries.map((entry) => toView(entry, wineMap)),
        ({ date }) => -new Date(date).getTime(),
      )
    },
  )

  export const getCellarDates = traced(
    'JournalQuery.getCellarDates',
    'domain.query',
    async (wineId: WineId) => {
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
    },
  )

  const toView = (entry: JournalEntry, wineMap: Record<string, Wine>): JournalEventView => {
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
