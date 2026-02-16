import { sortBy } from 'lodash-es'
import { Cellar } from '~/cellar/index'
import type { CellarHistoryEvent } from '~/cellar-history/types'
import { Wines } from '~/wine/index'

export namespace CellarHistory {
  export const list = async () => {
    const allEntries = await Cellar.getAllEntries()

    const events = await Promise.all(
      allEntries.flatMap(async (entry) => {
        const wine = await Wines.getById(entry.wineId)
        const wineName = wine !== 'not-found' ? (wine.name as string) : 'Vin inconnu'
        const wineColor = wine !== 'not-found' ? wine.color : 'red'
        const position = `${entry.row}${entry.col}`
        const base: CellarHistoryEvent = {
          type: 'entry',
          date: entry.dateIn,
          wineId: entry.wineId as string,
          wineName,
          wineColor,
          position,
        }

        if (!entry.dateOut) return [base]

        return [
          base,
          {
            ...base,
            type: 'exit' as const,
            date: entry.dateOut,
            rating: entry.rating as number | undefined,
            tastingNotes: entry.tastingNotes,
          },
        ]
      }),
    )

    return sortBy(events.flat(), (event) => -new Date(event.date).getTime())
  }
}
