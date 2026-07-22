import type { UserId } from '~/domain/shared/types'
import type { TastingNote } from '~/domain/tasting/types'
import { db } from '~/system/firebase'
import { genericDataConverter, userBeverageRecordRepository } from '~/utils/firestore'

export const { findAllByUser, findBy, findManyByBeverageIds, save, remove, removeAllByUser } =
  userBeverageRecordRepository<TastingNote>('tasting')

const tastings = () => db().collection('tasting').withConverter(genericDataConverter<TastingNote>())

// Only the favorited notes, queried as such — the dashboard's favorites section
// never needs the full tasting history.
export const findFavoritesByUser = async (userId: UserId): Promise<TastingNote[]> => {
  const snap = await tastings().where('userId', '==', userId).where('favorite', '==', true).get()
  return snap.docs.map((doc) => doc.data())
}
