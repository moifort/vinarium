import * as repository from '~/cellar-log/repository'
import type { CellarLogEntryIn, CellarLogEntryOut } from '~/cellar-log/types'

export namespace CellarLogCommand {
  export const bottleIn = (entry: CellarLogEntryIn) => repository.save(entry)

  export const bottleOut = (entry: CellarLogEntryOut) => repository.save(entry)
}
