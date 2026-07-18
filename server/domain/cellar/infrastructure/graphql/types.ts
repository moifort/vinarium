import { BeverageType } from '~/domain/beverage/infrastructure/graphql/types'
import { builder } from '~/domain/shared/graphql/builder'
import type {
  CellarBottle,
  CellarBottleOwner,
  CellarBottleView,
  CellarBottleWithWine,
} from '../../types'

export const CellarBottleOwnerType = builder
  .objectRef<CellarBottleOwner>('CellarBottleOwner')
  .implement({
    description:
      'Who a cellar bottle belongs to within a shared cellar.\n\n' +
      "In a solo cellar every bottle is the viewer's own; in a household, each bottle carries its owner so the UI can badge a housemate's wine. Attached to `CellarBottleWithWine`.",
    fields: (t) => ({
      userId: t.expose('userId', {
        type: 'UserId',
        description: 'Stable id of the member who owns this bottle.',
      }),
      displayName: t.expose('displayName', {
        type: 'PersonName',
        nullable: true,
        description: "Owner's display name, shown as a badge; null for the viewer's own bottles.",
      }),
      isMine: t.exposeBoolean('isMine', {
        description: 'Whether the bottle belongs to the viewer (no owner badge shown).',
      }),
    }),
  })

export const CellarBottleType = builder.objectRef<CellarBottleView>('CellarBottle').implement({
  description:
    'A bottle occupying a single slot of the cellar grid.\n\n' +
    "Identifies the wine plus its 0-based `row`/`col` coordinates and the human-facing `rowLabel`/`colLabel` derived from them. Exposed as `Beverage.cellar` (the bottle's physical slot), resolved through a per-request loader so a page of wines costs one cellar read, not one per wine.\n\n" +
    '```graphql\n' +
    '{ beverage(id: "...") { cellar { rowLabel colLabel } } }\n' +
    '```',
  fields: (t) => ({
    beverageId: t.expose('beverageId', {
      type: 'BeverageId',
      description: 'Id of the wine occupying this slot.',
    }),
    row: t.exposeInt('row', { description: 'Grid row index, 0-based (top to bottom).' }),
    col: t.exposeInt('col', { description: 'Grid column index, 0-based (left to right).' }),
    rowLabel: t.exposeString('rowLabel', {
      description: 'Human-facing row label derived from `row` (A, B, C, ...).',
    }),
    colLabel: t.exposeInt('colLabel', {
      description: 'Human-facing column label derived from `col` (1-based number).',
    }),
    createdAt: t.expose('createdAt', {
      type: 'DateTime',
      description: 'When the bottle was first placed in the cellar.',
    }),
    updatedAt: t.expose('updatedAt', {
      type: 'DateTime',
      description: 'When the bottle was last moved or updated.',
    }),
  }),
})

export const CellarBottleWithWineType = builder
  .objectRef<CellarBottleWithWine>('CellarBottleWithWine')
  .implement({
    description:
      'A placed cellar bottle joined with the wine it holds and its owner.\n\n' +
      'What the cave screen and dashboard render side by side: the slot coordinates, the full `Beverage`, and the `owner` badge. Returned in pages by `cellarBottles`.',
    fields: (t) => ({
      beverageId: t.expose('beverageId', {
        type: 'BeverageId',
        description: 'Id of the wine occupying this slot.',
      }),
      row: t.exposeInt('row', { description: 'Grid row index, 0-based.' }),
      col: t.exposeInt('col', { description: 'Grid column index, 0-based.' }),
      rowLabel: t.exposeString('rowLabel', {
        description: 'Human-facing row label derived from `row` (A, B, C, ...).',
      }),
      colLabel: t.exposeInt('colLabel', {
        description: 'Human-facing column label derived from `col` (1-based number).',
      }),
      createdAt: t.expose('createdAt', {
        type: 'DateTime',
        description: 'When the bottle was first placed in the cellar.',
      }),
      wine: t.field({
        type: BeverageType,
        description: 'The full wine held in this slot.',
        resolve: (b) => b.wine,
      }),
      owner: t.field({
        type: CellarBottleOwnerType,
        description: 'Which household member the bottle belongs to.',
        resolve: (b) => b.owner,
      }),
    }),
  })

export const CellarBottlesType = builder
  .objectRef<{ items: CellarBottleWithWine[]; hasMore: boolean }>('CellarBottles')
  .implement({
    description:
      'A page of placed cellar bottles joined with their wine.\n\n' +
      'Cursor-paginated result of `cellarBottles`, ordered by grid position.',
    fields: (t) => ({
      items: t.field({
        type: [CellarBottleWithWineType],
        description: 'The bottles in this page, in grid order.',
        resolve: ({ items }) => items,
      }),
      hasMore: t.exposeBoolean('hasMore', {
        description: 'Whether more bottles are available after this page.',
      }),
    }),
  })

export const CellarInfoType = builder
  .objectRef<{
    rows: number
    cols: number
    zones: number
    capacity: number
    placedCount: number
  }>('CellarInfo')
  .implement({
    description:
      'Dimensions and current usage of the cellar grid.\n\n' +
      'The configured grid size (`rows` x `cols`), its temperature `zones`, the total `capacity`, and how many slots are currently filled (`placedCount`). Also returned as the success arm of `ReconfigureCellarResult`.',
    fields: (t) => ({
      rows: t.exposeInt('rows', { description: 'Number of grid rows.' }),
      cols: t.exposeInt('cols', { description: 'Number of slots per row.' }),
      zones: t.exposeInt('zones', { description: 'Number of temperature zones (1..3).' }),
      capacity: t.exposeInt('capacity', {
        description: 'Total number of slots (`rows` x `cols`).',
      }),
      placedCount: t.exposeInt('placedCount', {
        description: 'How many slots currently hold a bottle.',
      }),
    }),
  })

export const CellarReconfigureBlockedType = builder
  .objectRef<{ outOfBounds: number }>('CellarReconfigureBlocked')
  .implement({
    description:
      'Reconfiguration refused because bottles would fall outside the requested grid.\n\n' +
      'Returned as the failure arm of `ReconfigureCellarResult` when shrinking the grid would strand already-placed bottles; the caller must move or remove them first.',
    fields: (t) => ({
      outOfBoundsCount: t.exposeInt('outOfBounds', {
        description: 'How many placed bottles would fall outside the new grid.',
      }),
    }),
  })

// Success returns the updated grid; refusal returns the count of stranded bottles.
export const ReconfigureCellarResultUnion = builder.unionType('ReconfigureCellarResult', {
  description:
    'Outcome of reconfiguring the cellar grid.\n\n' +
    'Resolves to `CellarInfo` on success (the updated grid) or `CellarReconfigureBlocked` when the new dimensions would strand placed bottles.',
  types: [CellarInfoType, CellarReconfigureBlockedType],
  resolveType: (value) => ('outOfBounds' in value ? 'CellarReconfigureBlocked' : 'CellarInfo'),
})

export const CellarPositionType = builder
  .objectRef<{
    row: CellarBottle['row']
    col: CellarBottle['col']
    rowLabel: string
    colLabel: number
  }>('CellarPosition')
  .implement({
    description:
      'A suggested free slot for placing the next bottle.\n\n' +
      'Returned by `suggestCellarPosition`: the first available grid coordinate with its human-facing labels, or null when the cellar is full.',
    fields: (t) => ({
      row: t.exposeInt('row', { description: 'Grid row index, 0-based.' }),
      col: t.exposeInt('col', { description: 'Grid column index, 0-based.' }),
      rowLabel: t.exposeString('rowLabel', {
        description: 'Human-facing row label derived from `row` (A, B, C, ...).',
      }),
      colLabel: t.exposeInt('colLabel', {
        description: 'Human-facing column label derived from `col` (1-based number).',
      }),
    }),
  })

// Extend BeverageType with the cellar nested field, batched by the per-request loader.
builder.objectField(BeverageType, 'cellar', (t) =>
  t.field({
    type: CellarBottleType,
    nullable: true,
    description:
      "The bottle's physical slot in the cellar grid.\n\n" +
      'Exposed as `Beverage.cellar`; null when the bottle is not currently placed in the cellar grid. Resolved through a per-request loader (no N+1).',
    resolve: async (wine, _, { loaders }) =>
      (await loaders.cellar.load({ id: wine.id, userId: wine.userId })) ?? null,
  }),
)
