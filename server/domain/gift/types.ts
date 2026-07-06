import type { PersonName, UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'

// One record per (user, wine) holding the two facets a bottle can have around
// gifting — both may coexist (received from someone, later given to someone else).
export type GiftGiven = { recipientName?: PersonName; date: Date }
export type GiftReceived = { from: PersonName }

export type Gift = {
  userId: UserId
  wineId: WineId
  given?: GiftGiven // I gave this bottle away (leaves the cellar)
  received?: GiftReceived // someone gave this bottle to me (provenance)
}
