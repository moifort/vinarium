import type { WineColor } from '~/wine/types'

export type ScanResult = {
  name: string
  domain: string | null
  vintage: number | null
  appellation: string | null
  region: string | null
  country: string | null
  color: WineColor
  grapeVarieties: string[]
  alcoholContent: number | null
  classification: string | null
  drinkFrom: number | null
  drinkUntil: number | null
  estimatedPrice: number | null
}

