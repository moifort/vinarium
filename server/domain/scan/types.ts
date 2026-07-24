import type { Brand } from 'ts-brand'
import type { BeverageSubtype, BeverageType, WineColor } from '~/domain/beverage/types'
import type { Language } from '~/domain/shared/language'

export type ImageHash = Brand<string, 'ImageHash'>

// The language the AI writes its free-text values in. Driven by the caller's
// `Accept-Language`, it also partitions the scan cache: the same label scanned
// in two languages yields two entries (see infrastructure/repository).
export type ScanLanguage = Language

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
  language: ScanLanguage
  result: ScanResult
  cachedAt: Date
}
