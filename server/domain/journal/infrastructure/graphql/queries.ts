import { builder } from '~/domain/shared/graphql/builder'
import { JournalQuery } from '../../query'
import { JournalEventType } from './types'

builder.queryField('journalEvents', (t) =>
  t.field({
    type: [JournalEventType],
    description: 'All cellar entry/exit events for the current user, most recent first',
    resolve: (_root, _args, { userId }) => JournalQuery.getAll(userId),
  }),
)
