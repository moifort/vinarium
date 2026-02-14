import { make } from 'ts-brand'
import { z } from 'zod'
import type { AnthropicApiKey as AnthropicApiKeyType } from '~/config/types'

export const AnthropicApiKey = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<AnthropicApiKeyType>()(v)
}
