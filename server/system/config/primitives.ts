import { make } from 'ts-brand'
import { z } from 'zod'
import type {
  AnthropicApiKey as AnthropicApiKeyType,
  ApiToken as ApiTokenType,
  GoogleApiKey as GoogleApiKeyType,
  SentryDsn as SentryDsnType,
  TransparentUrl as TransparentUrlType,
} from '~/system/config/types'

export const ApiToken = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<ApiTokenType>()(v)
}

export const AnthropicApiKey = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<AnthropicApiKeyType>()(v)
}

export const GoogleApiKey = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<GoogleApiKeyType>()(v)
}

export const SentryDsn = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<SentryDsnType>()(v)
}

export const TransparentUrl = (value: unknown) => {
  const v = z.string().url().parse(value)
  return make<TransparentUrlType>()(v)
}
