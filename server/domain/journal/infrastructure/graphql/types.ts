import { BeverageTypeEnum, WineColorEnum } from '~/domain/beverage/infrastructure/graphql/enums'
import { BeverageType } from '~/domain/beverage/infrastructure/graphql/types'
import { builder } from '~/domain/shared/graphql/builder'
import { JournalQuery } from '../../query'
import type { JournalEventActor, JournalEventView } from '../../types'

export const JournalEventTypeEnum = builder.enumType('JournalEventType', {
  description:
    'Whether a journal entry records a bottle entering or leaving the cellar.\n\n' +
    'Drives the direction of every audit-trail row in the journal.',
  values: {
    IN: { value: 'in', description: 'A bottle was placed into the cellar grid.' },
    OUT: { value: 'out', description: 'A bottle left the cellar (consumed, gifted, or removed).' },
  } as const,
})

export const JournalEventActorType = builder
  .objectRef<JournalEventActor>('JournalEventActor')
  .implement({
    description:
      'The household member who performed a cellar movement.\n\n' +
      "As seen by the viewer: their own events carry no name (the UI omits the badge), a housemate's event carries theirs.",
    fields: (t) => ({
      userId: t.expose('userId', {
        type: 'UserId',
        description: 'Stable id of the member who moved the bottle.',
      }),
      displayName: t.expose('displayName', {
        type: 'PersonName',
        nullable: true,
        description: "Actor's display name, shown as a badge; null for the viewer's own events.",
      }),
      isMine: t.exposeBoolean('isMine', {
        description: 'Whether the viewer moved the bottle themselves (no badge shown).',
      }),
    }),
  })

export const JournalEventType = builder.objectRef<JournalEventView>('JournalEvent').implement({
  description:
    'A single audit-trail entry recording a bottle moving in or out of the cellar.\n\n' +
    'Denormalized for display: it carries the wine name, type, and color alongside the grid `position`, the event `date`, and the `actor`. Pages of these form the shared cellar journal, and per-wine slices are exposed as `Beverage.history`.',
  fields: (t) => ({
    type: t.expose('type', {
      type: JournalEventTypeEnum,
      description: 'Whether the bottle entered or left the cellar.',
    }),
    date: t.expose('date', { type: 'DateTime', description: 'When the movement happened.' }),
    beverageId: t.expose('beverageId', {
      type: 'BeverageId',
      description: 'Id of the wine that moved.',
    }),
    beverageName: t.expose('beverageName', {
      type: 'BeverageName',
      description: 'Name of the wine at the time of the event.',
    }),
    wineBeverageType: t.expose('wineBeverageType', {
      type: BeverageTypeEnum,
      description: 'Kind of beverage (wine, spirit, ...) for display.',
    }),
    wineColor: t.expose('wineColor', {
      type: WineColorEnum,
      nullable: true,
      description: 'Wine color for display; null for non-wine beverages.',
    }),
    position: t.exposeString('position', {
      description: 'Human-facing grid slot the bottle occupied (e.g. "A1").',
    }),
    actor: t.field({
      type: JournalEventActorType,
      description: 'Which household member performed the movement.',
      resolve: (event) => event.actor,
    }),
  }),
})

export const JournalEventsType = builder
  .objectRef<{ items: JournalEventView[]; hasMore: boolean }>('JournalEvents')
  .implement({
    description:
      'A page of cellar journal events, most recent first.\n\n' +
      'Offset-paginated result of `journalEvents`.',
    fields: (t) => ({
      items: t.field({
        type: [JournalEventType],
        description: 'The events in this page, most recent first.',
        resolve: ({ items }) => items,
      }),
      hasMore: t.exposeBoolean('hasMore', {
        description: 'Whether more events are available after this page.',
      }),
    }),
  })

// Extend BeverageType with the per-wine history, batched by the per-request loader:
// a page of wines selecting `history` costs one journal query, not one per wine.
builder.objectField(BeverageType, 'history', (t) =>
  t.field({
    type: [JournalEventType],
    description:
      'Cellar entry/exit history for this wine, most recent first.\n\n' +
      'Exposed as `Beverage.history`; empty when the wine has never been placed. Resolved through a per-request loader, so a page of wines selecting `history` costs one journal query, not one per wine.',
    resolve: async (wine, _, { loaders, userId }) =>
      JournalQuery.historyOf(userId, wine, (await loaders.history.load(wine.id)) ?? []),
  }),
)
