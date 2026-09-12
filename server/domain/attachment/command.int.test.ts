import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type {
  Attachment,
  AttachmentId,
  ByteSize,
  ContentType,
  FileName,
  ObjectPath,
} from '~/domain/attachment/types'
import type { BeverageId } from '~/domain/beverage/types'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'
import { mockObjectStore } from '~/test/fake-object-store'

mock.module('~/system/firebase', () => ({ db: fakeDb }))
const fakeStorage = mockObjectStore()
const { objects: bucket, removed, put: store } = fakeStorage

const { AttachmentCommand } = await import('~/domain/attachment/command')

const userId = 'user-1' as UserId
const beverageId = 'wine-1' as BeverageId
const jpeg = 'image/jpeg' as ContentType
const fileName = 'etiquette.jpg' as FileName
const oneMegabyte = 1_000_000 as ByteSize

let fake = resetFakeFirestore()

const seedAttachments = (count: number) => {
  for (let i = 0; i < count; i++) {
    const id = `existing-${i}`
    fake.seed('attachments', id, {
      id: id as AttachmentId,
      userId,
      beverageId,
      kind: 'image',
      contentType: jpeg,
      fileName,
      size: oneMegabyte,
      objectPath: `attachments/${userId}/${beverageId}/${id}` as ObjectPath,
      createdAt: new Date(),
    } satisfies Attachment)
  }
}

beforeEach(() => {
  fake = resetFakeFirestore()
  fakeStorage.reset()
})

describe('AttachmentCommand.reserveSlot', () => {
  test('hands out an upload URL and stores nothing yet', async () => {
    const result = await AttachmentCommand.reserveSlot(userId, beverageId, jpeg, oneMegabyte)

    expect(result).not.toBeTypeOf('string')
    const pending = result as Exclude<typeof result, string>
    expect(pending.uploadUrl).toContain(`attachments/${userId}/${beverageId}/`)
    expect(pending.contentType).toBe(jpeg)
    expect(fake.snapshot('attachments').size).toBe(0)
  })

  test('refuses a media type the app would never render', async () => {
    const result = await AttachmentCommand.reserveSlot(
      userId,
      beverageId,
      'video/mp4' as ContentType,
      oneMegabyte,
    )

    expect(result).toBe('unsupported-type')
  })

  test('refuses a file past the size limit', async () => {
    const result = await AttachmentCommand.reserveSlot(
      userId,
      beverageId,
      jpeg,
      (11 * 1024 * 1024) as ByteSize,
    )

    expect(result).toBe('too-large')
  })

  test('refuses a sixth file on the same wine', async () => {
    seedAttachments(5)

    const result = await AttachmentCommand.reserveSlot(userId, beverageId, jpeg, oneMegabyte)

    expect(result).toBe('too-many')
  })

  test('sweeps an abandoned upload but spares one still in flight', async () => {
    const abandoned = `attachments/${userId}/${beverageId}/abandoned`
    const inFlight = `attachments/${userId}/${beverageId}/in-flight`
    store(abandoned, { storedAt: new Date(Date.now() - 60 * 60 * 1000) })
    store(inFlight, { storedAt: new Date() })

    await AttachmentCommand.reserveSlot(userId, beverageId, jpeg, oneMegabyte)

    expect(removed).toEqual([abandoned])
    expect(bucket.has(inFlight)).toBe(true)
  })
})

describe('AttachmentCommand.register', () => {
  const attachmentId = 'file-1' as AttachmentId
  const path = `attachments/${userId}/${beverageId}/${attachmentId}`

  test('records what the bucket really holds', async () => {
    store(path, { size: 4096 as ByteSize })

    const result = await AttachmentCommand.register(userId, beverageId, attachmentId, fileName)

    const attachment = result as Attachment
    expect(attachment.kind).toBe('image')
    expect(attachment.size).toBe(4096 as ByteSize)
    expect(attachment.objectPath).toBe(path as ObjectPath)
    expect(fake.snapshot('attachments').get(attachmentId)?.fileName).toBe(fileName)
  })

  test('refuses a slot nothing was uploaded to', async () => {
    const result = await AttachmentCommand.register(userId, beverageId, attachmentId, fileName)

    expect(result).toBe('upload-missing')
    expect(fake.snapshot('attachments').size).toBe(0)
  })

  // The whole reason the bucket is asked rather than the caller: a client is free
  // to announce one megabyte at reservation and push fifty at upload.
  test('refuses a file that came in larger than it announced, and drops it', async () => {
    store(path, { size: (50 * 1024 * 1024) as ByteSize })

    const result = await AttachmentCommand.register(userId, beverageId, attachmentId, fileName)

    expect(result).toBe('too-large')
    expect(removed).toContain(path)
    expect(fake.snapshot('attachments').size).toBe(0)
  })

  test('refuses a file whose real type is not one we accept, and drops it', async () => {
    store(path, { contentType: 'application/zip' as ContentType })

    const result = await AttachmentCommand.register(userId, beverageId, attachmentId, fileName)

    expect(result).toBe('unsupported-type')
    expect(removed).toContain(path)
  })

  test('holds the ceiling even when five were attached after the slot was reserved', async () => {
    seedAttachments(5)
    store(path)

    const result = await AttachmentCommand.register(userId, beverageId, attachmentId, fileName)

    expect(result).toBe('too-many')
    expect(removed).toContain(path)
  })
})

describe('AttachmentCommand.remove', () => {
  test('takes the bytes with the record', async () => {
    seedAttachments(1)
    const path = `attachments/${userId}/${beverageId}/existing-0`
    store(path)

    const result = await AttachmentCommand.remove(userId, 'existing-0' as AttachmentId)

    expect(result).toBeUndefined()
    expect(fake.snapshot('attachments').size).toBe(0)
    expect(bucket.has(path)).toBe(false)
  })

  test("refuses to delete someone else's attachment", async () => {
    seedAttachments(1)

    const result = await AttachmentCommand.remove(
      'someone-else' as UserId,
      'existing-0' as AttachmentId,
    )

    expect(result).toBe('not-found')
    expect(fake.snapshot('attachments').size).toBe(1)
  })
})

describe('cascading deletions', () => {
  // Deleting a beverage happens in two moves on purpose: the records go in the
  // caller's batch, the bytes only once that batch committed. A bucket cannot be
  // rolled back, so a single move would destroy the files of a bottle that a
  // failed commit left standing.
  test('a deleted beverage releases its records without touching the bytes yet', async () => {
    seedAttachments(3)
    store(`attachments/${userId}/${beverageId}/existing-0`)

    await AttachmentCommand.removeBeverage(beverageId)

    expect(fake.snapshot('attachments').size).toBe(0)
    expect(bucket.size).toBe(1)
  })

  test('erasing the files is the second move, keyed on the prefix so a retry finishes it', async () => {
    store(`attachments/${userId}/${beverageId}/existing-0`)
    store(`attachments/${userId}/${beverageId}/never-registered`)

    await AttachmentCommand.eraseFiles(userId, beverageId)
    await AttachmentCommand.eraseFiles(userId, beverageId)

    expect(bucket.size).toBe(0)
  })

  test('a deleted account takes every file it owned', async () => {
    seedAttachments(2)
    store(`attachments/${userId}/${beverageId}/existing-0`)
    store(`attachments/${userId}/other-wine/whatever`)

    await AttachmentCommand.deleteAllForUser(userId)

    expect(fake.snapshot('attachments').size).toBe(0)
    expect(bucket.size).toBe(0)
  })
})
