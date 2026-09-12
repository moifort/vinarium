import { ObjectPath } from '~/domain/attachment/primitives'
import type { AttachmentKind, ByteSize, ContentType } from '~/domain/attachment/types'
import type { BeverageId } from '~/domain/beverage/types'
import type { UserId } from '~/domain/shared/types'

/** Five files per beverage, whatever it is: a wine, a whisky, a beer. A cellar is
 *  a long-lived thing and storage is billed by the month forever, so the ceiling
 *  is part of the product, not a safety valve. */
export const MAX_ATTACHMENTS_PER_BEVERAGE = 5

/** Ten megabytes, the same ceiling the label scan already enforces. The app
 *  recompresses photos well below it; the limit is there for what it does not. */
export const MAX_ATTACHMENT_BYTES = 10 * 1024 * 1024

// What a bottle's paperwork actually looks like: photos taken or picked on the
// phone, and the PDF of an invoice or a producer's data sheet. Anything else is
// refused at the door rather than stored and never rendered.
const ACCEPTED: Record<string, AttachmentKind> = {
  'image/jpeg': 'image',
  'image/png': 'image',
  'image/heic': 'image',
  'image/heif': 'image',
  'image/webp': 'image',
  'application/pdf': 'document',
}

/** Undefined for a type we refuse — the caller turns that into a refusal. */
export const kindOf = (contentType: ContentType): AttachmentKind | undefined =>
  ACCEPTED[contentType]

export const acceptedContentTypes = Object.keys(ACCEPTED)

export const roomForAnother = (alreadyAttached: number) =>
  alreadyAttached < MAX_ATTACHMENTS_PER_BEVERAGE

export const withinSizeLimit = (size: ByteSize) => size > 0 && size <= MAX_ATTACHMENT_BYTES

/** Where a bottle's files live. The owner leads the path so an account deletion
 *  is one prefix to wipe, and the beverage follows so one bottle's files go together. */
export const prefixOf = (userId: UserId, beverageId: BeverageId) =>
  ObjectPath(`${userPrefixOf(userId)}${beverageId}/`)

export const userPrefixOf = (userId: UserId) => ObjectPath(`attachments/${userId}/`)

export const objectPathOf = (userId: UserId, beverageId: BeverageId, attachmentId: string) =>
  ObjectPath(`${prefixOf(userId, beverageId)}${attachmentId}`)

/** An object still inside its upload window may belong to a transfer in flight;
 *  only what is older than that, and unknown to the database, is really orphaned. */
export const orphaned = (storedAt: Date, now: Date) =>
  now.getTime() - storedAt.getTime() > UPLOAD_WINDOW_MS

export const UPLOAD_WINDOW_MS = 15 * 60 * 1000
