import { mkdir, readdir, readFile, rm, stat, writeFile } from 'node:fs/promises'
import { dirname, join } from 'node:path'
import { getStorage } from 'firebase-admin/storage'
import { UPLOAD_WINDOW_MS } from '~/domain/attachment/business-rules'
import { ByteSize, ContentType, ObjectPath, SignedUrl } from '~/domain/attachment/primitives'
import type {
  ContentType as ContentTypeValue,
  ObjectPath as ObjectPathValue,
  SignedUrl as SignedUrlValue,
  StoredObject,
} from '~/domain/attachment/types'
import { config } from '~/system/config'
// Side-effect import: the admin app must be initialized before getStorage().
import '~/system/firebase'

const DOWNLOAD_WINDOW_MS = 60 * 60 * 1000

// Where the bytes go. The bucket is private and its objects are never public:
// every read and every write goes through a URL this server signed, for one
// object, for a few minutes. Nothing else can reach them.
export type ObjectStore = {
  uploadUrl: (path: ObjectPathValue, contentType: ContentTypeValue) => Promise<SignedUrlValue>
  downloadUrl: (path: ObjectPathValue) => Promise<SignedUrlValue>
  stat: (path: ObjectPathValue) => Promise<StoredObject | null>
  remove: (path: ObjectPathValue) => Promise<void>
  removeByPrefix: (prefix: ObjectPathValue) => Promise<void>
  /** Every object under the prefix with the moment it landed — the orphan sweep
   *  needs the age to tell an abandoned upload from one still in flight. */
  list: (prefix: ObjectPathValue) => Promise<{ path: ObjectPathValue; storedAt: Date }[]>
}

const bucket = () => {
  const name = config().attachmentsBucket
  if (!name) throw new Error('NITRO_ATTACHMENTS_BUCKET is unset — attachments have nowhere to go')
  return getStorage().bucket(name)
}

// Signing without a private key on disk goes through the IAM signBlob API, so
// the runtime service account needs roles/iam.serviceAccountTokenCreator on
// itself (see infra/storage.tf). Without it every signature fails in production
// while local credentials keep working — the failure mode this comment exists for.
const gcs: ObjectStore = {
  uploadUrl: async (path, contentType) => {
    const [url] = await bucket()
      .file(path)
      .getSignedUrl({
        version: 'v4',
        action: 'write',
        expires: Date.now() + UPLOAD_WINDOW_MS,
        contentType,
      })
    return SignedUrl(url)
  },
  downloadUrl: async (path) => {
    const [url] = await bucket()
      .file(path)
      .getSignedUrl({
        version: 'v4',
        action: 'read',
        expires: Date.now() + DOWNLOAD_WINDOW_MS,
      })
    return SignedUrl(url)
  },
  stat: async (path) => {
    const file = bucket().file(path)
    const [exists] = await file.exists()
    if (!exists) return null
    const [metadata] = await file.getMetadata()
    return {
      contentType: ContentType(metadata.contentType ?? 'application/octet-stream'),
      size: ByteSize(Number(metadata.size ?? 0)),
    }
  },
  remove: async (path) => {
    await bucket().file(path).delete({ ignoreNotFound: true })
  },
  removeByPrefix: async (prefix) => {
    await bucket().deleteFiles({ prefix, force: true })
  },
  list: async (prefix) => {
    const [files] = await bucket().getFiles({ prefix })
    return files.map((file) => ({
      path: ObjectPath(file.name),
      storedAt: new Date(file.metadata.timeCreated ?? Date.now()),
    }))
  },
}

// The development stand-in. The Storage emulator cannot sign a V4 URL, and
// `scripts/e2e.sh` gates every release on a local stack, so the local store keeps
// the bytes on disk and points at the two dev-only routes under /dev/storage.
// Both it and those routes are compiled out of a production bundle.
const LOCAL_ROOT = '.data/attachments'
const localFile = (path: ObjectPathValue) => join(LOCAL_ROOT, path)
const localUrl = (path: ObjectPathValue) =>
  SignedUrl(`${config().publicBaseUrl}/dev/storage/${path}`)

const local: ObjectStore = {
  uploadUrl: async (path) => localUrl(path),
  downloadUrl: async (path) => localUrl(path),
  stat: async (path) => {
    try {
      const [bytes, contentType] = await Promise.all([
        readFile(localFile(path)),
        readFile(`${localFile(path)}.type`, 'utf8'),
      ])
      return { contentType: ContentType(contentType), size: ByteSize(bytes.byteLength) }
    } catch {
      return null
    }
  },
  remove: async (path) => {
    await rm(localFile(path), { force: true })
    await rm(`${localFile(path)}.type`, { force: true })
  },
  removeByPrefix: async (prefix) => {
    await rm(localFile(prefix), { force: true, recursive: true })
  },
  list: async (prefix) => {
    try {
      const names = await readdir(localFile(prefix))
      return await Promise.all(
        names
          .filter((name) => !name.endsWith('.type'))
          .map(async (name) => ({
            path: ObjectPath(`${prefix}${name}`),
            storedAt: (await stat(localFile(ObjectPath(`${prefix}${name}`)))).mtime,
          })),
      )
    } catch {
      return []
    }
  },
}

export const objectStore = (): ObjectStore => (import.meta.dev ? local : gcs)

/** Used by the dev-only upload route to put the bytes where `local` reads them. */
export const writeLocalObject = async (
  path: ObjectPathValue,
  body: Buffer,
  contentType: string,
) => {
  await mkdir(dirname(localFile(path)), { recursive: true })
  await writeFile(localFile(path), body)
  await writeFile(`${localFile(path)}.type`, contentType)
}

/** Used by the dev-only download route. */
export const readLocalObject = async (path: ObjectPathValue) => {
  const [body, contentType] = await Promise.all([
    readFile(localFile(path)),
    readFile(`${localFile(path)}.type`, 'utf8'),
  ])
  return { body, contentType }
}
