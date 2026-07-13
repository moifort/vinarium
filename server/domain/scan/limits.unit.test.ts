import { describe, expect, test } from 'bun:test'
import { imageWithinSizeLimit, MAX_BASE64_LENGTH, MAX_IMAGE_SIZE_BYTES } from '~/domain/scan/limits'

describe('scanWine upload size guard', () => {
  test('accepts a payload exactly at the limit', () => {
    expect(imageWithinSizeLimit(MAX_BASE64_LENGTH)).toBe(true)
  })

  test('rejects a payload one character over the limit', () => {
    expect(imageWithinSizeLimit(MAX_BASE64_LENGTH + 1)).toBe(false)
  })

  test('a 10 MB decoded image base64-encodes to a length that exceeds the limit', () => {
    // MAX_IMAGE_SIZE_BYTES is the decoded ceiling; base64 adds ~33 % overhead,
    // so a buffer of that size + 1 byte must produce a base64 string that fails the guard.
    const tenMbPlusOneBuffer = Buffer.alloc(MAX_IMAGE_SIZE_BYTES + 1)
    const base64 = tenMbPlusOneBuffer.toString('base64')
    expect(imageWithinSizeLimit(base64.length)).toBe(false)
  })
})
