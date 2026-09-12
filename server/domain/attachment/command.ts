import type { WriteBatch } from 'firebase-admin/firestore'
import {
  kindOf,
  objectPathOf,
  orphaned,
  prefixOf,
  roomForAnother,
  UPLOAD_WINDOW_MS,
  userPrefixOf,
  withinSizeLimit,
} from '~/domain/attachment/business-rules'
import { objectStore } from '~/domain/attachment/infrastructure/object-store'
import * as repository from '~/domain/attachment/infrastructure/repository'
import { randomAttachmentId } from '~/domain/attachment/primitives'
import type {
  Attachment,
  AttachmentId,
  ByteSize,
  ContentType,
  FileName,
} from '~/domain/attachment/types'
import type { BeverageId } from '~/domain/beverage/types'
import type { UserId } from '~/domain/shared/types'

export namespace AttachmentCommand {
  /** Hand out a one-object, few-minute upload URL. Nothing is stored yet: an
   *  upload the user abandons leaves no record, which is why the ceiling is
   *  checked again when the file comes back to be registered. */
  export const reserveSlot = async (
    userId: UserId,
    beverageId: BeverageId,
    contentType: ContentType,
    size: ByteSize,
  ) => {
    if (!kindOf(contentType)) return 'unsupported-type' as const
    if (!withinSizeLimit(size)) return 'too-large' as const

    const existing = await repository.findByBeverage(beverageId)
    if (!roomForAnother(existing.length)) return 'too-many' as const
    await sweepOrphans(userId, beverageId, existing)

    const attachmentId = randomAttachmentId()
    const uploadUrl = await objectStore().uploadUrl(
      objectPathOf(userId, beverageId, attachmentId),
      contentType,
    )
    return {
      attachmentId,
      uploadUrl,
      contentType,
      expiresAt: new Date(Date.now() + UPLOAD_WINDOW_MS),
    }
  }

  /** Turn an uploaded object into an attachment. The bucket, not the caller, is
   *  asked what was really sent: a client is free to announce one megabyte and
   *  push fifty, and the ceiling has to hold against that. */
  export const register = async (
    userId: UserId,
    beverageId: BeverageId,
    attachmentId: AttachmentId,
    fileName: FileName,
  ) => {
    const objectPath = objectPathOf(userId, beverageId, attachmentId)
    const stored = await objectStore().stat(objectPath)
    if (!stored) return 'upload-missing' as const

    // Anything refused is dropped from the bucket on the way out: bytes nobody
    // will ever read are still billed every month they stay.
    const kind = kindOf(stored.contentType)
    if (!kind) return await discard(objectPath, 'unsupported-type')
    if (!withinSizeLimit(stored.size)) return await discard(objectPath, 'too-large')
    const existing = await repository.findByBeverage(beverageId)
    if (!roomForAnother(existing.length)) return await discard(objectPath, 'too-many')

    return await repository.save({
      id: attachmentId,
      userId,
      beverageId,
      kind,
      contentType: stored.contentType,
      fileName,
      size: stored.size,
      objectPath,
      createdAt: new Date(),
    })
  }

  export const remove = async (userId: UserId, attachmentId: AttachmentId) => {
    const existing = await repository.findBy(attachmentId)
    if (!existing || existing.userId !== userId) return 'not-found' as const
    await repository.remove(attachmentId)
    await objectStore().remove(existing.objectPath)
    return undefined
  }

  /** Called when the beverage itself goes: enlists the records in the caller's
   *  batch so they vanish with it. The bytes are deliberately left alone. A bucket
   *  cannot join a Firestore batch, and erasing the files before the commit would
   *  destroy them for good the day the commit fails and the beverage stays. */
  export const removeBeverage = async (beverageId: BeverageId, batch?: WriteBatch) => {
    await repository.removeAllByBeverage(beverageId, batch)
  }

  /** The second half of the above, to be called once the deletion is committed.
   *  Keyed on the prefix rather than on the records, so a retry after a half-done
   *  deletion still clears everything. */
  export const eraseFiles = async (userId: UserId, beverageId: BeverageId) => {
    await objectStore().removeByPrefix(prefixOf(userId, beverageId))
  }

  /** An account deletion takes the files with it — the whole point of putting the
   *  owner first in the object path. */
  export const deleteAllForUser = async (userId: UserId) => {
    await repository.removeAllByUser(userId)
    await objectStore().removeByPrefix(userPrefixOf(userId))
  }

  const discard = async (objectPath: Attachment['objectPath'], refusal: string) => {
    await objectStore().remove(objectPath)
    return refusal as 'unsupported-type' | 'too-large' | 'too-many'
  }

  // An upload that never came back to be registered left bytes nobody points at.
  // Sweeping them when the next slot is reserved keeps the bucket self-healing
  // without a scheduled job, and costs one listing on an action that is rare.
  // Only objects past their upload window are touched, so a transfer still in
  // flight for the same bottle is never pulled from under the client.
  const sweepOrphans = async (userId: UserId, beverageId: BeverageId, known: Attachment[]) => {
    const kept = new Set(known.map(({ objectPath }) => objectPath))
    const stored = await objectStore().list(prefixOf(userId, beverageId))
    const now = new Date()
    await Promise.all(
      stored
        .filter(({ path, storedAt }) => !kept.has(path) && orphaned(storedAt, now))
        .map(({ path }) => objectStore().remove(path)),
    )
  }
}
