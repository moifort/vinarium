import type { Gift } from '~/domain/gift/types'
import { userBeverageRecordRepository } from '~/utils/firestore'

export const { findAllByUser, findBy, findManyByBeverageIds, save, remove, removeAllByUser } =
  userBeverageRecordRepository<Gift>('gift')
