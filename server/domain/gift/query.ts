import * as _repository from '~/domain/gift/repository'
import type { WineId } from '~/domain/wine/types'
import { traced, tracedModule } from '~/system/sentry/tracing'

const repository = tracedModule('gift', 'db', _repository)

export namespace GiftQuery {
  export const getAll = traced('GiftQuery.getAll', 'domain.query', async () => {
    return await repository.findAll()
  })

  export const getByWineId = traced(
    'GiftQuery.getByWineId',
    'domain.query',
    async (wineId: WineId) => {
      const gift = await repository.findBy(wineId)
      if (!gift) return 'not-found' as const
      return gift
    },
  )
}
