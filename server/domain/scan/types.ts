import type { Brand } from 'ts-brand'
import type { BeverageSubtype, BeverageType, WineColor } from '~/domain/beverage/types'

export type ImageHash = Brand<string, 'ImageHash'>

export type ScanResult = {
  // Whether the image was a recognizable beverage label. False signals the
  // client to show the "no result" screen rather than an empty review form.
  recognized: boolean
  name: string
  beverageType: BeverageType
  color?: WineColor
  subtype?: BeverageSubtype
  alcoholContent?: number
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
