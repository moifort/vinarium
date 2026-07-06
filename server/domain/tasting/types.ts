import type { Brand } from 'ts-brand'
import type { BeverageId } from '~/domain/beverage/types'
import type { UserId } from '~/domain/shared/types'

export type Rating = Brand<number, 'Rating'>

export type TastingNote = {
  userId: UserId
  beverageId: BeverageId
  consumedDate?: Date
  rating?: Rating
  tastingNotes?: string
  contacts?: string[]
  favorite?: boolean
}
