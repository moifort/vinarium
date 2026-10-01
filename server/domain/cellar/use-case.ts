import type { BeverageId } from '~/domain/beverage/types'
import { CellarCommand } from '~/domain/cellar/command'
import type { CellarCols, CellarName, CellarRows, CellarZones } from '~/domain/cellar/types'
import { EntitlementQuery } from '~/domain/entitlement/query'
import { GiftCommand } from '~/domain/gift/command'
import type { GiftGiven } from '~/domain/gift/types'
import type { UserId } from '~/domain/shared/types'
import { TastingCommand } from '~/domain/tasting/command'
import type { TastingNote } from '~/domain/tasting/types'

type GiftReason = { type: 'gift'; given: GiftGiven }
type TastingReason = { type: 'tasting' } & Omit<TastingNote, 'beverageId' | 'userId'>
export type RemovalReason = GiftReason | TastingReason

export namespace CellarUseCase {
  // A second cellar, and every one after, is a Premium feature. Only creating one
  // is gated: a cellar created while subscribed stays usable once Premium lapses,
  // since locking bottles away would hold the user's own data hostage.
  export const createCellar = async (
    userId: UserId,
    name: CellarName,
    size: { rows: CellarRows; cols: CellarCols; zones: CellarZones },
  ) => {
    if ((await EntitlementQuery.planOf(userId)) !== 'premium') return 'premium-required' as const
    return CellarCommand.create(userId, name, size)
  }

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
