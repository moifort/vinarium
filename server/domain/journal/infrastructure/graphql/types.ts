import { builder } from '~/domain/shared/graphql/builder'
import { BeverageTypeEnum, WineColorEnum } from '~/domain/wine/infrastructure/graphql/enums'
import { WineType } from '~/domain/wine/infrastructure/graphql/types'
import { JournalQuery } from '../../query'
import type { JournalEventView } from '../../types'

export const JournalEventTypeEnum = builder.enumType('JournalEventType', {
  description: 'Whether a journal entry records a bottle entering or leaving the cellar',
  values: { IN: { value: 'in' }, OUT: { value: 'out' } } as const,
})

export const JournalEventType = builder.objectRef<JournalEventView>('JournalEvent').implement({
  description: 'A timestamped cellar entry/exit event for a wine',
  fields: (t) => ({
    type: t.expose('type', { type: JournalEventTypeEnum }),
    date: t.expose('date', { type: 'DateTime' }),
    wineId: t.expose('wineId', { type: 'WineId' }),
    wineName: t.expose('wineName', { type: 'WineName' }),
    wineBeverageType: t.expose('wineBeverageType', { type: BeverageTypeEnum }),
    wineColor: t.expose('wineColor', { type: WineColorEnum, nullable: true }),
    position: t.exposeString('position'),
  }),
})

export const JournalEventsType = builder
  .objectRef<{ items: JournalEventView[]; hasMore: boolean }>('JournalEvents')
  .implement({
    description: 'A page of cellar journal events',
    fields: (t) => ({
      items: t.field({ type: [JournalEventType], resolve: ({ items }) => items }),
      hasMore: t.exposeBoolean('hasMore', {
        description: 'Whether more events are available after this page',
      }),
    }),
  })

// Extend WineType with the per-wine history
builder.objectField(WineType, 'history', (t) =>
  t.field({
    type: [JournalEventType],
    description: 'Cellar entry/exit history for this wine, most recent first',
    resolve: (wine, _, { userId }) =>
      JournalQuery.getAllByWineId(userId, {
        id: wine.id,
        name: wine.name,
        beverageType: wine.beverageType,
        color: wine.color,
      }),
  }),
)
