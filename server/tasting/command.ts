import * as repository from '~/tasting/repository'
import type { TastingNote } from '~/tasting/types'

export namespace TastingCommand {
  export const create = async (note: TastingNote) => {
    return await repository.save(note)
  }
}
