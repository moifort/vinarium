import { AnthropicApiKey, GoogleApiKey } from '~/config/primitives'

export const config = () => {
  const runtimeConfig = useRuntimeConfig()
  return {
    anthropicApiKey: AnthropicApiKey(runtimeConfig.anthropicApiKey),
    googleApiKey: GoogleApiKey(runtimeConfig.googleApiKey),
  }
}
