import type { Brand } from 'ts-brand'
import type { WineColor } from '~/domain/wine/types'

export type ImageHash = Brand<string, 'ImageHash'>

export type ScanResult = {
  name: string
  color: WineColor
  domain?: string
  vintage?: number
  appellation?: string
  region?: string
  country?: string
  grapeVarieties?: string[]
  classification?: string
  drinkFrom?: number
  drinkUntil?: number
  estimatedPrice?: number
}

export type CachedScanResult = {
  imageHash: ImageHash
  result: ScanResult
  cachedAt: Date
}
