import * as repository from '~/tasting/repository'
import type { WineId } from '~/wine/types'

export namespace TastingQuery {
  export const getAll = async () => {
    return await repository.findAll()
  }

  export const getByWineId = async (wineId: WineId) => {
    const note = await repository.findBy(wineId)
    if (!note) return 'not-found' as const
    return note
  }
}
