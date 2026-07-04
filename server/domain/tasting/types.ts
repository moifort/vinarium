import type { Brand } from 'ts-brand'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'

export type Rating = Brand<number, 'Rating'>

export type TastingNote = {
  userId: UserId
  wineId: WineId
  consumedDate?: Date
  rating?: Rating
  tastingNotes?: string
  contacts?: string[]
  favorite?: boolean
}
