import { builder } from '~/domain/shared/graphql/builder'
import { JournalQuery } from '../../query'
import { JournalEventsType } from './types'

builder.queryField('journalEvents', (t) =>
  t.field({
    type: JournalEventsType,
    description: 'A page of cellar entry/exit events for the current user, most recent first',
    args: {
      limit: t.arg.int({ defaultValue: 15 }),
      offset: t.arg.int({ defaultValue: 0 }),
    },
    resolve: (_root, args, { userId }) =>
      JournalQuery.page(userId, { limit: args.limit ?? 15, offset: args.offset ?? 0 }),
  }),
)
