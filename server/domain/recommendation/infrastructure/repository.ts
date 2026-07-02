import type { Recommendation } from '~/domain/recommendation/types'
import { userWineRecordRepository } from '~/utils/firestore'

export const { findAllByUser, findBy, save, remove, removeAllByUser } =
  userWineRecordRepository<Recommendation>('recommendation')
