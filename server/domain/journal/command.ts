import * as repository from '~/domain/journal/repository'
import type { JournalEntryIn, JournalEntryOut } from '~/domain/journal/types'
import type { WineId } from '~/domain/wine/types'

export namespace JournalCommand {
  export const bottleIn = (entry: JournalEntryIn) => repository.save(entry)

  export const bottleOut = (entry: JournalEntryOut) => repository.save(entry)

  export const removeWine = async (wineId: WineId) => {
    await repository.removeByWineId(wineId)
  }
}
