import { make } from 'ts-brand'
import { z } from 'zod'
import type {
  AdminToken as AdminTokenType,
  ApiToken as ApiTokenType,
  GoogleApiKey as GoogleApiKeyType,
  SentryDsn as SentryDsnType,
} from '~/system/config/types'

export const ApiToken = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<ApiTokenType>()(v)
}

export const AdminToken = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<AdminTokenType>()(v)
}

export const GoogleApiKey = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<GoogleApiKeyType>()(v)
}

export const SentryDsn = (value: unknown) => {
  // Any non-empty string, like the other config secrets: Sentry.init validates
  // the DSN format itself (warns and disables on a bad one) rather than throwing,
  // so a malformed value can't take down config() — which auth and scan also call.
  const v = z.string().min(1).parse(value)
  return make<SentryDsnType>()(v)
}
