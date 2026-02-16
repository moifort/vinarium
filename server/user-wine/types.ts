import type { WineColor } from '~/wine/types'

export type UserWineDetail = {
  id: string
  name: string
  color: WineColor
  grapeVarieties: string[]
  createdAt: Date
  updatedAt: Date
  domain?: string
  vintage?: number
  appellation?: string
  region?: string
  country?: string
  alcoholContent?: number
  classification?: string
  purchasePrice?: number
  purchaseDate?: string
  drinkFrom?: number
  drinkUntil?: number
  notes?: string
  cellar?: {
    row: string
    col: number
    dateIn: Date
  }
  consumption?: {
    dateOut: Date
    consumedDate?: Date
    rating?: number
    tastingNotes?: string
  }
}
