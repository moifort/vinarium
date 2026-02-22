import type { PersonName } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'

export type Gift = {
  wineId: WineId
  giftedDate: Date
  recipientName?: PersonName
}
