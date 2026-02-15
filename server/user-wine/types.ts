import type { WineColor } from '~/wine/types'

export type UserWineDetail = {
  id: string
  name: string
  color: WineColor
  domain: string | null
  vintage: number | null
  appellation: string | null
  region: string | null
  country: string | null
  grapeVarieties: string[]
  alcoholContent: number | null
  classification: string | null
  purchasePrice: number | null
  purchaseDate: string | null
  drinkFrom: number | null
  drinkUntil: number | null
  notes: string | null
  createdAt: Date
  updatedAt: Date
  cellar: {
    row: string
    col: number
    dateIn: Date
  } | null
  consumption: {
    dateOut: Date
    consumedDate: Date | null
    rating: number | null
    tastingNotes: string | null
  } | null
}
