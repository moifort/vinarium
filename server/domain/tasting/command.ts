import * as _repository from '~/domain/tasting/repository'
import type { TastingNote } from '~/domain/tasting/types'
import type { WineId } from '~/domain/wine/types'
import { tracedModule } from '~/system/sentry/tracing'

const repository = tracedModule('tasting', 'db', _repository)

export namespace TastingCommand {
  export const create = async (note: TastingNote) => {
    return await repository.save(note)
  }

  export const removeWine = async (wineId: WineId) => {
    await repository.remove(wineId)
  }
}
