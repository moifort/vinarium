import { readLocalObject } from '~/domain/attachment/infrastructure/object-store'
import { ObjectPath } from '~/domain/attachment/primitives'

// The read half of the development object store — see the .put route next to it.
export default defineEventHandler(async (event) => {
  if (!import.meta.dev) throw createError({ statusCode: 404, statusMessage: 'Not found' })

  const path = getRouterParam(event, 'path')
  if (!path) throw createError({ statusCode: 400, statusMessage: 'Missing object path' })

  try {
    const { body, contentType } = await readLocalObject(ObjectPath(path))
    setResponseHeader(event, 'content-type', contentType)
    return body
  } catch {
    throw createError({ statusCode: 404, statusMessage: 'Not found' })
  }
})
