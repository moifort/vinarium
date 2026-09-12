import { writeLocalObject } from '~/domain/attachment/infrastructure/object-store'
import { ObjectPath } from '~/domain/attachment/primitives'

// Development stand-in for a signed upload to Cloud Storage. The Storage emulator
// cannot sign a V4 URL, and `scripts/e2e.sh` gates every release on the local
// stack, so the bytes land on disk here instead. `import.meta.dev` is resolved at
// build time: this handler does not exist in a deployed bundle.
export default defineEventHandler(async (event) => {
  if (!import.meta.dev) throw createError({ statusCode: 404, statusMessage: 'Not found' })

  const path = getRouterParam(event, 'path')
  if (!path) throw createError({ statusCode: 400, statusMessage: 'Missing object path' })

  const body = await readRawBody(event, false)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'Empty body' })

  await writeLocalObject(
    ObjectPath(path),
    body,
    getHeader(event, 'content-type') ?? 'application/octet-stream',
  )
  setResponseStatus(event, 200)
  return ''
})
