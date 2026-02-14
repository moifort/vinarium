import type { Brand } from 'ts-brand'
import type { Country, Eur, Region, Year } from '~/types'

export type WineId = Brand<string, 'WineId'>
export type WineName = Brand<string, 'WineName'>
export type AlcoholContent = Brand<number, 'AlcoholContent'>
export type WineColor = 'red' | 'white' | 'rosé' | 'sparkling' | 'sweet'

export type Wine = {
  id: WineId
  name: WineName
  color: WineColor
  domain?: string
  vintage?: Year
  appellation?: string
  region?: Region
  country?: Country
  grapeVarieties?: string[]
  alcoholContent?: AlcoholContent
  classification?: string
  purchasePrice?: Eur
  purchaseDate?: string
  drinkFrom?: Year
  drinkUntil?: Year
  imageBase64?: string
  notes?: string
  createdAt: Date
  updatedAt: Date
}
