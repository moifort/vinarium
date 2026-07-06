import { builder } from '~/domain/shared/graphql/builder'
import { DashboardQuery } from '../../query'
import { DashboardType } from './types'

builder.queryField('dashboard', (t) =>
  t.field({
    type: DashboardType,
    description: 'Aggregated dashboard view for the current user',
    resolve: (_root, _args, { userId }) => DashboardQuery.view(userId),
  }),
)
