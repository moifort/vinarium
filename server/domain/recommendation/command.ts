import * as _repository from '~/domain/recommendation/repository'
import type { Recommendation } from '~/domain/recommendation/types'
import type { WineId } from '~/domain/wine/types'
import { tracedModule } from '~/system/sentry/tracing'

const repository = tracedModule('recommendation', 'db', _repository)

export namespace RecommendationCommand {
  export const create = async (recommendation: Recommendation) => {
    return await repository.save(recommendation)
  }

  export const removeWine = async (wineId: WineId) => {
    await repository.remove(wineId)
  }
}
