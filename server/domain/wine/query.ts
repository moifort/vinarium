import * as repository from '~/domain/wine/repository'
import type { WineId } from '~/domain/wine/types'

export namespace WineQuery {
  export const findAll = async () => {
    return repository.findAll()
  }

  export const getById = async (id: WineId) => {
    const wine = await repository.findBy(id)
    if (!wine) return 'not-found' as const
    return wine
  }
}
