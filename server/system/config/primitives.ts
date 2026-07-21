import { Environment } from '@apple/app-store-server-library'
import { make } from 'ts-brand'
import { z } from 'zod'
import { UserId } from '~/domain/shared/primitives'
import type { UserId as UserIdType } from '~/domain/shared/types'
import type {
  AdminToken as AdminTokenType,
  ApiToken as ApiTokenType,
  AppleAppId as AppleAppIdType,
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

// The app's numeric App Store identifier, required to verify a Production
// signature (Apple omits it in the sandbox). Blank until the app has an id.
export const AppleAppId = (value: unknown) => {
  const v = z.coerce.number().int().positive().parse(value)
  return make<AppleAppIdType>()(v)
}

// Pins signature verification to one App Store environment. Blank means both
// Production and Sandbox are tried, which is what a shipped app needs (TestFlight
// and review sign in Sandbox); `Xcode` is for the local StoreKit configuration file.
export const AppleEnvironment = (value: unknown) => z.enum(Environment).parse(value) as Environment

// The accounts granted Premium outright (the maker's own, a reviewer's), as one
// comma-separated list of Firebase uids. An override on top of a real entitlement,
// never the source of one.
export const PremiumUserIds = (value: unknown): UserIdType[] =>
  z
    .string()
    .parse(value ?? '')
    .split(',')
    .map((id) => id.trim())
    .filter((id) => id.length > 0)
    .map((id) => UserId(id))
