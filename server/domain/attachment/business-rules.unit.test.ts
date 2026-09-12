import { describe, expect, test } from 'bun:test'
import {
  kindOf,
  MAX_ATTACHMENT_BYTES,
  MAX_ATTACHMENTS_PER_BEVERAGE,
  objectPathOf,
  orphaned,
  prefixOf,
  roomForAnother,
  UPLOAD_WINDOW_MS,
  userPrefixOf,
  withinSizeLimit,
} from '~/domain/attachment/business-rules'
import type { ByteSize, ContentType } from '~/domain/attachment/types'
import type { BeverageId } from '~/domain/beverage/types'
import type { UserId } from '~/domain/shared/types'

const type = (value: string) => value as ContentType
const size = (value: number) => value as ByteSize
const userId = 'user-1' as UserId
const beverageId = 'wine-1' as BeverageId

describe('kindOf', () => {
  test('shows photos inline', () => {
    expect(kindOf(type('image/jpeg'))).toBe('image')
    expect(kindOf(type('image/heic'))).toBe('image')
  })

  test('opens a PDF as a document', () => {
    expect(kindOf(type('application/pdf'))).toBe('document')
  })

  test('refuses anything else', () => {
    expect(kindOf(type('video/mp4'))).toBeUndefined()
    expect(kindOf(type('application/zip'))).toBeUndefined()
    expect(kindOf(type('text/html'))).toBeUndefined()
  })
})

describe('roomForAnother', () => {
  test('accepts up to the ceiling', () => {
    expect(roomForAnother(0)).toBe(true)
    expect(roomForAnother(MAX_ATTACHMENTS_PER_BEVERAGE - 1)).toBe(true)
  })

  test('refuses at and beyond the ceiling', () => {
    expect(roomForAnother(MAX_ATTACHMENTS_PER_BEVERAGE)).toBe(false)
    expect(roomForAnother(MAX_ATTACHMENTS_PER_BEVERAGE + 1)).toBe(false)
  })
})

describe('withinSizeLimit', () => {
  test('accepts a file up to the limit', () => {
    expect(withinSizeLimit(size(1))).toBe(true)
    expect(withinSizeLimit(size(MAX_ATTACHMENT_BYTES))).toBe(true)
  })

  test('refuses an empty file and one past the limit', () => {
    expect(withinSizeLimit(size(0))).toBe(false)
    expect(withinSizeLimit(size(MAX_ATTACHMENT_BYTES + 1))).toBe(false)
  })
})

describe('object paths', () => {
  test('put the owner first so an account deletion is one prefix', () => {
    expect(userPrefixOf(userId)).toBe('attachments/user-1/')
    expect(prefixOf(userId, beverageId)).toBe('attachments/user-1/wine-1/')
    expect(objectPathOf(userId, beverageId, 'file-1')).toBe('attachments/user-1/wine-1/file-1')
  })
})

describe('orphaned', () => {
  const now = new Date('2026-09-12T12:00:00Z')

  test('spares an upload still inside its window', () => {
    expect(orphaned(new Date(now.getTime() - UPLOAD_WINDOW_MS + 1000), now)).toBe(false)
  })

  test('claims one that outlived it', () => {
    expect(orphaned(new Date(now.getTime() - UPLOAD_WINDOW_MS - 1000), now)).toBe(true)
  })
})
