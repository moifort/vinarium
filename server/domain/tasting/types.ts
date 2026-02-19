import type { Brand } from 'ts-brand'
import type { WineId } from '~/domain/wine/types'

export type Rating = Brand<number, 'Rating'>

export type TastingNote = {
  wineId: WineId
  consumedDate?: Date
  rating?: Rating
  tastingNotes?: string
}
