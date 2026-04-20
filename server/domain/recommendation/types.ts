import type { PersonName, UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'

export type Recommendation = {
  userId: UserId
  wineId: WineId
  recommenderName?: PersonName
  comment?: string
}
