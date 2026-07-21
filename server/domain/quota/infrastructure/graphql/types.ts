import { PlanEnum } from '~/domain/entitlement/infrastructure/graphql/enums'
import { limitOf, remaining, renewsOn } from '~/domain/quota/business-rules'
import type { Quota } from '~/domain/quota/types'
import { builder } from '~/domain/shared/graphql/builder'
import type { Plan } from '~/domain/shared/types'

// What the `quota` query answers: the plan, and this month's consumption under it.
export type QuotaState = { plan: Plan; quota: Quota }

export const QuotaType = builder.objectRef<QuotaState>('Quota').implement({
  description:
    'The monthly scan allowance: what has been spent, what is left, and when it renews.\n\n' +
    'Only the AI scan is metered. Adding a bottle by hand, the cellar, tastings and sharing are ' +
    'unlimited on every plan, so a spent allowance never stops the app being used.',
  fields: (t) => ({
    plan: t.field({
      type: PlanEnum,
      description: 'The plan the allowance is read for, e.g. `FREE`',
      resolve: (state) => state.plan,
    }),
    used: t.int({
      description: 'How many scans were spent this month, e.g. `2`',
      resolve: (state) => state.quota.scans,
    }),
    limit: t.int({
      description: 'How many the plan allows in a month, e.g. `5`',
      resolve: (state) => limitOf(state.plan),
    }),
    remaining: t.int({
      description:
        'How many are left, e.g. `3`. Never negative: an allowance already overspent reads as `0`.',
      resolve: (state) => remaining(state.plan, state.quota),
    }),
    renewsOn: t.field({
      type: 'DateTime',
      description:
        'When the counter goes back to zero: midnight UTC on the 1st of the next month, e.g. ' +
        '`"2026-08-01T00:00:00.000Z"`',
      resolve: (state) => renewsOn(state.quota.month),
    }),
  }),
})
