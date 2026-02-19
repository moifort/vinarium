import * as repository from '~/domain/gift/repository'
import type { Gift } from '~/domain/gift/types'

export namespace GiftCommand {
  export const giveTo = async (gift: Gift) => {
    return await repository.save(gift)
  }
}
