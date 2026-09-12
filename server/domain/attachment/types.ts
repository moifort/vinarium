import type { Brand } from 'ts-brand'
import type { BeverageId } from '~/domain/beverage/types'
import type { UserId } from '~/domain/shared/types'

export type AttachmentId = Brand<string, 'AttachmentId'>
export type FileName = Brand<string, 'FileName'>
export type ContentType = Brand<string, 'ContentType'>
export type ByteSize = Brand<number, 'ByteSize'>
/** Where the bytes live in the bucket. Derived from the owner, the beverage and
 *  the attachment id, never chosen by the caller. */
export type ObjectPath = Brand<string, 'ObjectPath'>
/** A time-limited URL to read or write one object, signed by the server. */
export type SignedUrl = Brand<string, 'SignedUrl'>

/** What the file is, as the app treats it: an image is shown inline, a document
 *  is opened in a viewer. The content type decides which (see business-rules). */
export type AttachmentKind = 'image' | 'document'

/** One file kept alongside a bottle: a label photo, the cellar door it came from,
 *  the invoice. Owned by the user who attached it, and only by them. */
export type Attachment = {
  id: AttachmentId
  userId: UserId
  beverageId: BeverageId
  kind: AttachmentKind
  contentType: ContentType
  fileName: FileName
  size: ByteSize
  objectPath: ObjectPath
  createdAt: Date
}

/** The slot handed to the client before it uploads. Nothing is stored yet: the
 *  attachment exists only once the bytes are in the bucket and confirmed. */
export type PendingUpload = {
  attachmentId: AttachmentId
  uploadUrl: SignedUrl
  /** The exact header the client must send. A V4 signature covers `Content-Type`,
   *  so a value that differs by one character is rejected by the bucket. */
  contentType: ContentType
  expiresAt: Date
}

/** An attachment as it is read: the record plus the short-lived URL to fetch it. */
export type AttachmentView = Attachment & { url: SignedUrl }

/** What the bucket knows about an object, read back to check what was really sent. */
export type StoredObject = { contentType: ContentType; size: ByteSize }
