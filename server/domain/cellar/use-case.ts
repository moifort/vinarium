import type { BeverageId } from '~/domain/beverage/types'
import { CellarCommand } from '~/domain/cellar/command'
import { GiftCommand } from '~/domain/gift/command'
import type { GiftGiven } from '~/domain/gift/types'
import type { UserId } from '~/domain/shared/types'
import { TastingCommand } from '~/domain/tasting/command'
import type { TastingNote } from '~/domain/tasting/types'

type GiftReason = { type: 'gift'; given: GiftGiven }
type TastingReason = { type: 'tasting' } & Omit<TastingNote, 'beverageId' | 'userId'>
export type RemovalReason = GiftReason | TastingReason

export namespace CellarUseCase {
  export const removeBottle = async (
    actorId: UserId,
    beverageId: BeverageId,
    reason?: RemovalReason,
  ) => {
    const result = await CellarCommand.removeBeverage(actorId, beverageId)
    if (result === 'not-in-cellar') return 'not-in-cellar' as const

    if (reason?.type === 'gift') {
      // The owner's wine was given away — the gift record is theirs.
      await GiftCommand.giveTo(result.ownerId, beverageId, reason.given)
    } else if (reason?.type === 'tasting') {
      // A tasting note is always the actor's own, even on a housemate's bottle.
      const { type: _t, ...tasting } = reason
      await TastingCommand.create({ userId: actorId, beverageId, ...tasting })
    }
    return undefined
  }
}
