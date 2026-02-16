import type { Brand } from 'ts-brand'
import type { WineId } from '~/wine/types'

export type Rating = Brand<number, 'Rating'>

export type UserLogEntry = {
  wineId: WineId
  consumedDate?: Date
  rating?: Rating
  tastingNotes?: string
}
