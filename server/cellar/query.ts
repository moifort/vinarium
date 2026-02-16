import * as repository from '~/cellar/repository'
import { CellarGrid } from '~/cellar-grid/index'
import type { WineId } from '~/wine/types'

export namespace CellarQuery {
  export const getAllEntries = () => repository.findAll()

  export const getEntryByWineId = (wineId: WineId) => repository.findBy(wineId)

  export const suggestPosition = async (wineId: WineId) => {
    const allEntries = await repository.findAll()
    return CellarGrid.suggest(wineId, allEntries)
  }

  export const getGrid = async () => {
    const allEntries = await repository.findAll()
    return CellarGrid.get(allEntries)
  }
}
