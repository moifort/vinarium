import type { PersonName } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'

export type Recommendation = {
  wineId: WineId
  recommenderName?: PersonName
  comment?: string
}
