import { AnthropicApiKey } from '~/config/primitives'

export const config = () => {
  const runtimeConfig = useRuntimeConfig()
  return {
    anthropicApiKey: AnthropicApiKey(runtimeConfig.anthropicApiKey),
  }
}
