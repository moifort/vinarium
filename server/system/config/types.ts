import type { Brand } from 'ts-brand'

export type ApiToken = Brand<string, 'ApiToken'>
export type AdminToken = Brand<string, 'AdminToken'>
export type GoogleApiKey = Brand<string, 'GoogleApiKey'>
export type SentryDsn = Brand<string, 'SentryDsn'>
/** The app's numeric App Store id, which a Production signature is verified
 *  against. Public, not a credential. */
export type AppleAppId = Brand<number, 'AppleAppId'>
