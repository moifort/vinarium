import { CellarCol, CellarRow } from '~/cellar/primitives'
import * as repository from '~/cellar/repository'
import type { CellarEntry, CellarEntryView } from '~/cellar/types'
import { CellarGrid } from '~/cellar-grid/index'
import type { WineId } from '~/wine/types'

const toView = (entry: CellarEntry): CellarEntryView => ({
  ...entry,
  rowLabel: CellarRow.toLabel(entry.row),
  colLabel: CellarCol.toLabel(entry.col),
})

export namespace CellarQuery {
  export const getAllEntries = async () => {
    const entries = await repository.findAll()
    return entries.map(toView)
  }

  export const getEntryByWineId = async (wineId: WineId) => {
    const entry = await repository.findBy(wineId)
    return entry ? toView(entry) : null
  }

  export const suggestPosition = async (wineId: WineId) => {
    const allEntries = await repository.findAll()
    return CellarGrid.suggest(wineId, allEntries)
  }

  export const getGrid = async () => {
    const allEntries = await repository.findAll()
    return CellarGrid.get(allEntries)
  }
}
