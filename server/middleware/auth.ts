export default defineEventHandler((event) => {
  const config = useRuntimeConfig(event)
  const token = config.apiToken
  if (!token) return
  const auth = getHeader(event, 'authorization')
  if (auth !== `Bearer ${token}`)
    throw createError({ statusCode: 401, statusMessage: 'Unauthorized' })
})
