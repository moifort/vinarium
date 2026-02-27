import * as _repository from '~/domain/journal/repository'
import type { JournalEntryIn, JournalEntryOut } from '~/domain/journal/types'
import type { WineId } from '~/domain/wine/types'
import { traced, tracedModule } from '~/system/sentry/tracing'

const repository = tracedModule('journal', 'db', _repository)

export namespace JournalCommand {
  export const bottleIn = traced(
    'JournalCommand.bottleIn',
    'domain.command',
    (entry: JournalEntryIn) => repository.save(entry),
  )

  export const bottleOut = traced(
    'JournalCommand.bottleOut',
    'domain.command',
    (entry: JournalEntryOut) => repository.save(entry),
  )

  export const removeWine = traced(
    'JournalCommand.removeWine',
    'domain.command',
    async (wineId: WineId) => {
      await repository.removeByWineId(wineId)
    },
  )
}
