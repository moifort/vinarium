import { monthOf } from '~/domain/quota/business-rules'
import * as repository from '~/domain/quota/infrastructure/repository'
import type { Quota } from '~/domain/quota/types'
import type { UserId } from '~/domain/shared/types'

export namespace QuotaQuery {
  // What this account has spent in the month it is currently living in. Never
  // absent: a month nobody has touched reads back at zero.
  export const ofCurrentMonth = (userId: UserId): Promise<Quota> =>
    repository.findBy(userId, monthOf(new Date()))
}
