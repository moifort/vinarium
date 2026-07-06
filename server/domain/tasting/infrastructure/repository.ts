import type { TastingNote } from '~/domain/tasting/types'
import { userBeverageRecordRepository } from '~/utils/firestore'

export const { findAllByUser, findBy, findManyByBeverageIds, save, remove, removeAllByUser } =
  userBeverageRecordRepository<TastingNote>('tasting')
