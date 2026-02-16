import { make } from 'ts-brand'
import { z } from 'zod'
import type {
  AnthropicApiKey as AnthropicApiKeyType,
  GoogleApiKey as GoogleApiKeyType,
} from '~/config/types'

export const AnthropicApiKey = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<AnthropicApiKeyType>()(v)
}

export const GoogleApiKey = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<GoogleApiKeyType>()(v)
}
