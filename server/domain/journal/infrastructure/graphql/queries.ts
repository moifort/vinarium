import { builder } from '~/domain/shared/graphql/builder'
import { JournalQuery } from '../../query'
import { JournalEventsType } from './types'

builder.queryField('journalEvents', (t) =>
  t.field({
    type: JournalEventsType,
    description: 'A page of entry/exit events for the shared cellar, most recent first',
    args: {
      limit: t.arg.int({ defaultValue: 15, description: 'Maximum events returned in the page' }),
      offset: t.arg.int({ defaultValue: 0, description: 'Number of events to skip' }),
    },
    resolve: (_root, args, { userId }) =>
      JournalQuery.page(userId, { limit: args.limit ?? 15, offset: args.offset ?? 0 }),
  }),
)
