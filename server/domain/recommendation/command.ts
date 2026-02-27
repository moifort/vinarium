import * as _repository from '~/domain/recommendation/repository'
import type { Recommendation } from '~/domain/recommendation/types'
import type { WineId } from '~/domain/wine/types'
import { traced, tracedModule } from '~/system/sentry/tracing'

const repository = tracedModule('recommendation', 'db', _repository)

export namespace RecommendationCommand {
  export const create = traced(
    'RecommendationCommand.create',
    'domain.command',
    async (recommendation: Recommendation) => {
      return await repository.save(recommendation)
    },
  )

  export const removeWine = traced(
    'RecommendationCommand.removeWine',
    'domain.command',
    async (wineId: WineId) => {
      await repository.remove(wineId)
    },
  )
}
