import { builder } from '~/domain/shared/graphql/builder'
import { pageLimit } from '~/utils/input'
import { JournalQuery } from '../../query'
import { JournalEventsType } from './types'

builder.queryField('journalEvents', (t) =>
  t.field({
    type: JournalEventsType,
    description: 'A page of entry/exit events for the shared cellar, most recent first',
    args: {
      limit: t.arg.int({
        defaultValue: 15,
        description: 'Maximum events returned in the page, at most 100',
      }),
      after: t.arg({
        type: 'JournalEntryId',
        description:
          "Cursor: return the page following this entry — the previous page's `endCursor`.",
      }),
      offset: t.arg.int({
        defaultValue: 0,
        description: 'Number of events to skip. Ignored when `after` is given.',
        deprecationReason: 'Every skipped event is billed as a read: page with `after` instead.',
      }),
    },
    resolve: (_root, args, { userId }) =>
      JournalQuery.page(userId, {
        limit: pageLimit(args.limit, 15, 100),
        offset: args.offset ?? 0,
        after: args.after ?? undefined,
      }),
  }),
)
