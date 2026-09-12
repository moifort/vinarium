import type { WriteBatch } from 'firebase-admin/firestore'
import type { Attachment, AttachmentId } from '~/domain/attachment/types'
import type { BeverageId } from '~/domain/beverage/types'
import type { UserId } from '~/domain/shared/types'
import { db } from '~/system/firebase'
import { deleteInBatches, genericDataConverter } from '~/utils/firestore'

// One document per file, keyed by its own id: a bottle carries several, so the
// `${userId}_${beverageId}` layout of the other satellites does not apply here.
const attachments = () =>
  db().collection('attachments').withConverter(genericDataConverter<Attachment>())

// Firestore caps an `in` filter at 30 values; a page of wines exceeds that.
const IN_CHUNK = 30

export const findBy = async (id: AttachmentId): Promise<Attachment | null> => {
  const doc = await attachments().doc(id).get()
  return doc.data() ?? null
}

export const findByBeverage = async (beverageId: BeverageId): Promise<Attachment[]> => {
  const snap = await attachments().where('beverageId', '==', beverageId).get()
  return snap.docs.map((doc) => doc.data())
}

// Batch-load the files of a page of wines. Keyed on the beverage alone, never on
// the viewer: a housemate's bottle placed in the shared cellar shows its files,
// and whether the viewer may see that bottle at all was already settled upstream.
export const findManyByBeverageIds = async (beverageIds: BeverageId[]): Promise<Attachment[]> => {
  if (beverageIds.length === 0) return []
  const chunks: BeverageId[][] = []
  for (let i = 0; i < beverageIds.length; i += IN_CHUNK)
    chunks.push(beverageIds.slice(i, i + IN_CHUNK))
  const snaps = await Promise.all(
    chunks.map((chunk) => attachments().where('beverageId', 'in', chunk).get()),
  )
  return snaps.flatMap((snap) => snap.docs.map((doc) => doc.data()))
}

export const save = async (attachment: Attachment): Promise<Attachment> => {
  await attachments().doc(attachment.id).set(attachment)
  return attachment
}

export const remove = async (id: AttachmentId, batch?: WriteBatch): Promise<void> => {
  const ref = attachments().doc(id)
  if (batch) batch.delete(ref)
  else await ref.delete()
}

export const removeAllByBeverage = async (
  beverageId: BeverageId,
  batch?: WriteBatch,
): Promise<void> => {
  const snap = await attachments().where('beverageId', '==', beverageId).get()
  if (batch) for (const doc of snap.docs) batch.delete(doc.ref)
  else await deleteInBatches(snap.docs.map((doc) => doc.ref))
}

export const removeAllByUser = async (userId: UserId): Promise<void> => {
  const snap = await attachments().where('userId', '==', userId).get()
  await deleteInBatches(snap.docs.map((doc) => doc.ref))
}
