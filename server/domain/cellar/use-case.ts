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
    userId: UserId,
    beverageId: BeverageId,
    reason?: RemovalReason,
  ) => {
    const error = await CellarCommand.removeBeverage(userId, beverageId)
    if (error === 'not-in-cellar') return 'not-in-cellar' as const

    if (reason?.type === 'gift') {
      await GiftCommand.giveTo(userId, beverageId, reason.given)
    } else if (reason?.type === 'tasting') {
      const { type: _t, ...tasting } = reason
      await TastingCommand.create({ userId, beverageId, ...tasting })
    }
    return undefined
  }
}
