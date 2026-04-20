import type { PersonName, UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'

export type Gift = {
  userId: UserId
  wineId: WineId
  giftedDate: Date
  recipientName?: PersonName
}
