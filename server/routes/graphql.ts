import { type ApolloServer, HeaderMap } from '@apollo/server'
import { createLoaders } from '~/domain/shared/graphql/loaders'
import type { UserId } from '~/domain/shared/types'
import { createLogger } from '~/system/logger'

const log = createLogger('graphql')

type GraphQLBody = { operationName?: string | null }

const extractOperationName = (body: unknown): string => {
  if (body && typeof body === 'object' && 'operationName' in body) {
    const op = (body as GraphQLBody).operationName
    if (typeof op === 'string' && op.length > 0) return op
  }
  return 'anonymous'
}

export default defineEventHandler(async (event) => {
  const apollo = useApollo()
  const userId = (event.context as { userId?: UserId }).userId
  if (!userId) throw createError({ statusCode: 401, statusMessage: 'Missing user context' })

  const headerMap = new HeaderMap()
  for (const [key, value] of Object.entries(getHeaders(event))) {
    if (value !== undefined) headerMap.set(key, value)
  }

  if (event.method === 'GET') {
    const query = getQuery(event)
    const search = new URLSearchParams()
    for (const [key, value] of Object.entries(query)) {
      if (value !== undefined) search.set(key, String(value))
    }
    const response = await apollo.executeHTTPGraphQLRequest({
      httpGraphQLRequest: {
        method: 'GET',
        headers: headerMap,
        body: undefined,
        search: search.toString(),
      },
      context: async () => ({ event, loaders: createLoaders(), userId }),
    })
    return sendApolloResponse(event, response)
  }

  const body = await readBody(event)
  const operation = extractOperationName(body)
  log.info(`→ ${operation} (user ${userId})`)

  const response = await apollo.executeHTTPGraphQLRequest({
    httpGraphQLRequest: { method: 'POST', headers: headerMap, body, search: '' },
    context: async () => ({ event, loaders: createLoaders(), userId }),
  })
  return sendApolloResponse(event, response)
})

function sendApolloResponse(
  event: Parameters<typeof setResponseStatus>[0],
  response: Awaited<ReturnType<ApolloServer['executeHTTPGraphQLRequest']>>,
) {
  setResponseStatus(event, response.status || 200)
  for (const [key, value] of response.headers) setResponseHeader(event, key, value)
  if (response.body.kind === 'complete') return response.body.string
  throw createError({ statusCode: 500, statusMessage: 'Chunked responses not supported' })
}
