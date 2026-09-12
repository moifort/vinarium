import { make } from 'ts-brand'
import { z } from 'zod'
import type {
  AttachmentId as AttachmentIdType,
  ByteSize as ByteSizeType,
  ContentType as ContentTypeType,
  FileName as FileNameType,
  ObjectPath as ObjectPathType,
  SignedUrl as SignedUrlType,
} from '~/domain/attachment/types'

export const AttachmentId = (value: unknown) => {
  const v = z.string().uuid().parse(value)
  return make<AttachmentIdType>()(v)
}

export const randomAttachmentId = () => AttachmentId(crypto.randomUUID())

// A display name, never a path: the slashes and the traversal segments are
// stripped before branding, because this string is shown next to a document and
// must not be able to designate another object.
export const FileName = (value: unknown) => {
  const v = z
    .string()
    .min(1)
    .max(255)
    .transform((name) => name.replaceAll('/', '-').replaceAll('..', '-'))
    .parse(value)
  return make<FileNameType>()(v)
}

// A bare MIME type, lowercased. Whether it is one we accept is a business rule,
// not a shape: this only refuses what could not be a media type at all.
export const ContentType = (value: unknown) => {
  const v = z
    .string()
    .regex(/^[a-z]+\/[a-z0-9.+-]+$/i, 'not a media type')
    .transform((type) => type.toLowerCase())
    .parse(value)
  return make<ContentTypeType>()(v)
}

export const ByteSize = (value: unknown) => {
  const v = z.number().int().nonnegative().parse(value)
  return make<ByteSizeType>()(v)
}

export const ObjectPath = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<ObjectPathType>()(v)
}

export const SignedUrl = (value: unknown) => {
  const v = z.string().url().parse(value)
  return make<SignedUrlType>()(v)
}
