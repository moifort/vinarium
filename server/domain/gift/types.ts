import type { Brand } from 'ts-brand'
import type { WineId } from '~/domain/wine/types'

export type RecipientName = Brand<string, 'RecipientName'>

export type Gift = {
  wineId: WineId
  giftedDate: Date
  recipientName?: RecipientName
}
