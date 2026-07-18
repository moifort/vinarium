import { getAuth } from 'firebase-admin/auth'
import { UserId } from '~/domain/shared/primitives'
// Side-effect import: ensures firebase-admin is initialized before verifyIdToken.
import '~/system/firebase'
import { config } from '~/system/config'

export default defineEventHandler(async (event) => {
  const path = event.path ?? ''

  // Admin endpoints (separate token, never a Firebase user)
  if (path.startsWith('/admin/')) {
    const auth = getHeader(event, 'authorization')
    const adminToken = config().adminToken
    if (!adminToken || auth !== `Bearer ${adminToken}`)
      throw createError({ statusCode: 401, statusMessage: 'Unauthorized' })
    return
  }

  // Public app configuration: read by the update gate, possibly signed out.
  if (path === '/app-config' || path.startsWith('/app-config?')) return

  // Everything else (incl. /graphql): require a valid Firebase ID token.
  const auth = getHeader(event, 'authorization')

  // Dev-only: let a browser reach Apollo Sandbox without a Firebase token.
  // import.meta.dev is compile-time, so this block is tree-shaken out of prod builds.
  if (import.meta.dev && !auth) {
    const devUserId = config().devUserId
    if (!devUserId)
      throw createError({
        statusCode: 401,
        statusMessage: 'Dev auth bypass needs NITRO_DEV_USER_ID in .env (a Firebase UID)',
      })
    event.context.userId = UserId(devUserId)
    return
  }

  const token = auth?.startsWith('Bearer ') ? auth.slice(7) : null
  if (!token) throw createError({ statusCode: 401, statusMessage: 'Missing bearer token' })

  try {
    const decoded = await getAuth().verifyIdToken(token)
    event.context.userId = UserId(decoded.uid)
  } catch {
    throw createError({ statusCode: 401, statusMessage: 'Invalid token' })
  }
})

declare module 'h3' {
  interface H3EventContext {
    userId?: ReturnType<typeof UserId>
  }
}
