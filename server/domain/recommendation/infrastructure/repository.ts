import type { Recommendation } from '~/domain/recommendation/types'
import { userBeverageRecordRepository } from '~/utils/firestore'

export const { findAllByUser, findBy, findManyByBeverageIds, save, remove, removeAllByUser } =
  userBeverageRecordRepository<Recommendation>('recommendation')
