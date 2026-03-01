import * as repository from '~/domain/gift/repository'
import type { Gift } from '~/domain/gift/types'
import type { WineId } from '~/domain/wine/types'

export namespace GiftCommand {
  export const giveTo = async (gift: Gift) => {
    return await repository.save(gift)
  }

  export const removeWine = async (wineId: WineId) => {
    await repository.remove(wineId)
  }
}
