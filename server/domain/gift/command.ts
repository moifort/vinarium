import * as _repository from '~/domain/gift/repository'
import type { Gift } from '~/domain/gift/types'
import type { WineId } from '~/domain/wine/types'
import { traced, tracedModule } from '~/system/sentry/tracing'

const repository = tracedModule('gift', 'db', _repository)

export namespace GiftCommand {
  export const giveTo = traced('GiftCommand.giveTo', 'domain.command', async (gift: Gift) => {
    return await repository.save(gift)
  })

  export const removeWine = traced(
    'GiftCommand.removeWine',
    'domain.command',
    async (wineId: WineId) => {
      await repository.remove(wineId)
    },
  )
}
