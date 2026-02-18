import * as repository from '~/domain/cellar-log/repository'
import type { CellarLogEntryIn, CellarLogEntryOut } from '~/domain/cellar-log/types'

export namespace CellarLogCommand {
  export const bottleIn = (entry: CellarLogEntryIn) => repository.save(entry)

  export const bottleOut = (entry: CellarLogEntryOut) => repository.save(entry)
}
