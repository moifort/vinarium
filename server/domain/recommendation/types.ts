import type { BeverageId } from '~/domain/beverage/types'
import type { PersonName, UserId } from '~/domain/shared/types'

export type Recommendation = {
  userId: UserId
  beverageId: BeverageId
  recommenderName?: PersonName
  comment?: string
}
