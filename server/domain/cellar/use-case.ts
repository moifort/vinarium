import { CellarCommand } from '~/domain/cellar/command'
import { GiftCommand } from '~/domain/gift/command'
import type { Gift } from '~/domain/gift/types'
import type { UserId } from '~/domain/shared/types'
import { TastingCommand } from '~/domain/tasting/command'
import type { TastingNote } from '~/domain/tasting/types'
import type { WineId } from '~/domain/wine/types'

type GiftReason = { type: 'gift' } & Omit<Gift, 'wineId' | 'userId'>
type TastingReason = { type: 'tasting' } & Omit<TastingNote, 'wineId' | 'userId'>
export type RemovalReason = GiftReason | TastingReason

export namespace CellarUseCase {
  export const removeBottle = async (userId: UserId, wineId: WineId, reason?: RemovalReason) => {
    const error = await CellarCommand.removeWine(userId, wineId)
    if (error === 'not-in-cellar') return 'not-in-cellar' as const

    if (reason?.type === 'gift') {
      const { type: _t, ...gift } = reason
      await GiftCommand.giveTo({ userId, wineId, ...gift })
    } else if (reason?.type === 'tasting') {
      const { type: _t, ...tasting } = reason
      await TastingCommand.create({ userId, wineId, ...tasting })
    }
    return undefined
  }
}
