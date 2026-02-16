import * as repository from '~/user-log/repository'
import type { UserLogEntry } from '~/user-log/types'
import type { WineId } from '~/wine/types'

export namespace UserLog {
  export const create = async (entry: UserLogEntry) => {
    await repository.save(entry)
    return entry
  }

  export const getByWineId = (wineId: WineId) => repository.getByWineId(wineId)
}
