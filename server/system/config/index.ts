import {
  AdminToken,
  ApiToken,
  AppleAppId,
  AppleEnvironment,
  GoogleApiKey,
  PremiumUserIds,
  SentryDsn,
} from '~/system/config/primitives'

export const config = () => {
  const runtimeConfig = useRuntimeConfig()
  return {
    apiToken: runtimeConfig.apiToken ? ApiToken(runtimeConfig.apiToken) : undefined,
    adminToken: runtimeConfig.adminToken ? AdminToken(runtimeConfig.adminToken) : undefined,
    googleApiKey: GoogleApiKey(runtimeConfig.googleApiKey),
    sentryDsn: runtimeConfig.sentryDsn ? SentryDsn(runtimeConfig.sentryDsn) : undefined,
    devUserId: runtimeConfig.devUserId || undefined,
    appleAppId: runtimeConfig.appleAppId ? AppleAppId(runtimeConfig.appleAppId) : undefined,
    appleEnvironment: runtimeConfig.appleEnvironment
      ? AppleEnvironment(runtimeConfig.appleEnvironment)
      : undefined,
    premiumUserIds: PremiumUserIds(runtimeConfig.premiumUserIds),
  }
}
