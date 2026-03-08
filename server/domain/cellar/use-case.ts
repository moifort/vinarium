import { CellarCommand } from '~/domain/cellar/command'
import { GiftCommand } from '~/domain/gift/command'
import type { Gift } from '~/domain/gift/types'
import { TastingCommand } from '~/domain/tasting/command'
import type { TastingNote } from '~/domain/tasting/types'
import type { WineId } from '~/domain/wine/types'

type GiftReason = { type: 'gift' } & Omit<Gift, 'wineId'>
type TastingReason = { type: 'tasting' } & Omit<TastingNote, 'wineId'>
export type RemovalReason = GiftReason | TastingReason

export namespace CellarUseCase {
  export const removeBottle = async (wineId: WineId, reason?: RemovalReason) => {
    const error = await CellarCommand.removeWine(wineId)
    if (error === 'not-in-cellar') return 'not-in-cellar' as const

    if (reason?.type === 'gift') {
      const { type, ...gift } = reason
      await GiftCommand.giveTo({ wineId, ...gift })
    } else if (reason?.type === 'tasting') {
      const { type, ...tasting } = reason
      await TastingCommand.create({ wineId, ...tasting })
    }
    return undefined
  }
}
