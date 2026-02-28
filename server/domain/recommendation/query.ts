import * as _repository from '~/domain/recommendation/repository'
import type { WineId } from '~/domain/wine/types'
import { tracedModule } from '~/system/sentry/tracing'

const repository = tracedModule('recommendation', 'db', _repository)

export namespace RecommendationQuery {
  export const getAll = async () => {
    return await repository.findAll()
  }

  export const getByWineId = async (wineId: WineId) => {
    const recommendation = await repository.findBy(wineId)
    if (!recommendation) return 'not-found' as const
    return recommendation
  }
}
