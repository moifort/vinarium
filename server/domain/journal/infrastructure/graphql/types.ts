import { BeverageTypeEnum, WineColorEnum } from '~/domain/beverage/infrastructure/graphql/enums'
import { BeverageType } from '~/domain/beverage/infrastructure/graphql/types'
import { builder } from '~/domain/shared/graphql/builder'
import { JournalQuery } from '../../query'
import type { JournalEventActor, JournalEventView } from '../../types'

export const JournalEventTypeEnum = builder.enumType('JournalEventType', {
  description: 'Whether a journal entry records a bottle entering or leaving the cellar',
  values: { IN: { value: 'in' }, OUT: { value: 'out' } } as const,
})

export const JournalEventActorType = builder
  .objectRef<JournalEventActor>('JournalEventActor')
  .implement({
    description: 'The household member who moved the bottle',
    fields: (t) => ({
      userId: t.expose('userId', { type: 'UserId' }),
      displayName: t.expose('displayName', { type: 'PersonName', nullable: true }),
      isMine: t.exposeBoolean('isMine', {
        description: 'Whether the viewer moved the bottle themselves (no badge shown)',
      }),
    }),
  })

export const JournalEventType = builder.objectRef<JournalEventView>('JournalEvent').implement({
  description: 'A timestamped cellar entry/exit event for a wine',
  fields: (t) => ({
    type: t.expose('type', { type: JournalEventTypeEnum }),
    date: t.expose('date', { type: 'DateTime' }),
    beverageId: t.expose('beverageId', { type: 'BeverageId' }),
    beverageName: t.expose('beverageName', { type: 'BeverageName' }),
    wineBeverageType: t.expose('wineBeverageType', { type: BeverageTypeEnum }),
    wineColor: t.expose('wineColor', { type: WineColorEnum, nullable: true }),
    position: t.exposeString('position'),
    actor: t.field({ type: JournalEventActorType, resolve: (event) => event.actor }),
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

// Extend BeverageType with the per-wine history, batched by the per-request loader:
// a page of wines selecting `history` costs one journal query, not one per wine.
builder.objectField(BeverageType, 'history', (t) =>
  t.field({
    type: [JournalEventType],
    description: 'Cellar entry/exit history for this wine, most recent first',
    resolve: async (wine, _, { loaders, userId }) =>
      JournalQuery.historyOf(userId, wine, (await loaders.history.load(wine.id)) ?? []),
  }),
)
