import * as repository from '~/domain/tasting/repository'
import type { TastingNote } from '~/domain/tasting/types'

export namespace TastingCommand {
  export const create = async (note: TastingNote) => {
    return await repository.save(note)
  }
}
