import * as _repository from '~/domain/gift/repository'
import type { WineId } from '~/domain/wine/types'
import { tracedModule } from '~/system/sentry/tracing'

const repository = tracedModule('gift', 'db', _repository)

export namespace GiftQuery {
  export const getAll = async () => {
    return await repository.findAll()
  }

  export const getByWineId = async (wineId: WineId) => {
    const gift = await repository.findBy(wineId)
    if (!gift) return 'not-found' as const
    return gift
  }
}
