import type { WriteBatch } from 'firebase-admin/firestore'
import type { BeverageId } from '~/domain/beverage/types'
import * as repository from '~/domain/journal/infrastructure/repository'
import type { JournalEntry, JournalEntryIn, JournalEntryOut } from '~/domain/journal/types'
import type { UserId } from '~/domain/shared/types'
import { bulkSave } from '~/utils/firestore'

export namespace JournalCommand {
  export const bottleIn = (
    userId: UserId,
    entry: Omit<JournalEntryIn, 'userId'>,
    batch?: WriteBatch,
  ) => repository.save({ ...entry, userId }, batch)

  export const bottleOut = (
    userId: UserId,
    entry: Omit<JournalEntryOut, 'userId'>,
    batch?: WriteBatch,
  ) => repository.save({ ...entry, userId }, batch)

  export const removeBeverage = async (
    userId: UserId,
    beverageId: BeverageId,
    batch?: WriteBatch,
  ) => {
    await repository.removeByBeverageId(userId, beverageId, batch)
  }

  // Wipe the user's journal and restore the given entries (account import).
  export const replaceAllForUser = async (userId: UserId, entries: JournalEntry[]) => {
    await repository.removeAllByUser(userId)
    await bulkSave(entries, repository.save)
  }
}
