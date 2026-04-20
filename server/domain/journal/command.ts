import * as repository from '~/domain/journal/infrastructure/repository'
import type { JournalEntryIn, JournalEntryOut } from '~/domain/journal/types'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'

export namespace JournalCommand {
  export const bottleIn = (userId: UserId, entry: Omit<JournalEntryIn, 'userId'>) =>
    repository.save({ ...entry, userId })

  export const bottleOut = (userId: UserId, entry: Omit<JournalEntryOut, 'userId'>) =>
    repository.save({ ...entry, userId })

  export const removeWine = async (userId: UserId, wineId: WineId) => {
    await repository.removeByWineId(userId, wineId)
  }
}
