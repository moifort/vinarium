import type { Gift } from '~/domain/gift/types'
import { userWineRecordRepository } from '~/utils/firestore'

export const { findAllByUser, findBy, save, remove, removeAllByUser } =
  userWineRecordRepository<Gift>('gift')
