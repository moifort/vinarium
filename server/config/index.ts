import { AnthropicApiKey, ApiToken, GoogleApiKey } from '~/config/primitives'

export const config = () => {
  const runtimeConfig = useRuntimeConfig()
  return {
    apiToken: runtimeConfig.apiToken ? ApiToken(runtimeConfig.apiToken) : undefined,
    anthropicApiKey: AnthropicApiKey(runtimeConfig.anthropicApiKey),
    googleApiKey: GoogleApiKey(runtimeConfig.googleApiKey),
  }
}
