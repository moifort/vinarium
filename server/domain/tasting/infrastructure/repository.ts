import type { TastingNote } from '~/domain/tasting/types'
import { userWineRecordRepository } from '~/utils/firestore'

export const { findAllByUser, findBy, save, remove, removeAllByUser } =
  userWineRecordRepository<TastingNote>('tasting')
