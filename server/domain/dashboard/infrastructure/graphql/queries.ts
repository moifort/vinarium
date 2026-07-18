import { builder } from '~/domain/shared/graphql/builder'
import { DashboardQuery } from '../../query'
import { DashboardType } from './types'

builder.queryField('dashboard', (t) =>
  t.field({
    type: DashboardType,
    description:
      'Read-only home-screen summary for the current user.\n\n' +
      'Returns cellar counters, total value, drink-window alerts, favorites and recent journal ' +
      'activity in a single payload. Everything is derived from the user records; the dashboard ' +
      'itself is never written.',
    resolve: (_root, _args, { userId }) => DashboardQuery.view(userId),
  }),
)
