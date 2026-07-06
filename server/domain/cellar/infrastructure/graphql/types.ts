import { BeverageType } from '~/domain/beverage/infrastructure/graphql/types'
import { builder } from '~/domain/shared/graphql/builder'
import type { CellarBottle, CellarBottleView, CellarBottleWithWine } from '../../types'

export const CellarBottleType = builder.objectRef<CellarBottleView>('CellarBottle').implement({
  description: 'A bottle physically placed in the cellar grid',
  fields: (t) => ({
    beverageId: t.expose('beverageId', { type: 'BeverageId' }),
    row: t.exposeInt('row'),
    col: t.exposeInt('col'),
    rowLabel: t.exposeString('rowLabel'),
    colLabel: t.exposeInt('colLabel'),
    createdAt: t.expose('createdAt', { type: 'DateTime' }),
    updatedAt: t.expose('updatedAt', { type: 'DateTime' }),
  }),
})

export const CellarBottleWithWineType = builder
  .objectRef<CellarBottleWithWine>('CellarBottleWithWine')
  .implement({
    description: 'A cellar bottle joined with the corresponding wine',
    fields: (t) => ({
      beverageId: t.expose('beverageId', { type: 'BeverageId' }),
      row: t.exposeInt('row'),
      col: t.exposeInt('col'),
      rowLabel: t.exposeString('rowLabel'),
      colLabel: t.exposeInt('colLabel'),
      createdAt: t.expose('createdAt', { type: 'DateTime' }),
      wine: t.field({ type: BeverageType, resolve: (b) => b.wine }),
    }),
  })

export const CellarBottlesType = builder
  .objectRef<{ items: CellarBottleWithWine[]; hasMore: boolean }>('CellarBottles')
  .implement({
    description: 'A page of cellar bottles joined with their wine',
    fields: (t) => ({
      items: t.field({ type: [CellarBottleWithWineType], resolve: ({ items }) => items }),
      hasMore: t.exposeBoolean('hasMore', {
        description: 'Whether more bottles are available after this page',
      }),
    }),
  })

export const CellarInfoType = builder
  .objectRef<{ rows: number; cols: number; capacity: number; placedCount: number }>('CellarInfo')
  .implement({
    description: 'Configuration and current usage of the cellar grid',
    fields: (t) => ({
      rows: t.exposeInt('rows'),
      cols: t.exposeInt('cols'),
      capacity: t.exposeInt('capacity'),
      placedCount: t.exposeInt('placedCount'),
    }),
  })

export const CellarPositionType = builder
  .objectRef<{
    row: CellarBottle['row']
    col: CellarBottle['col']
    rowLabel: string
    colLabel: number
  }>('CellarPosition')
  .implement({
    description: 'A free cellar position suggestion',
    fields: (t) => ({
      row: t.exposeInt('row'),
      col: t.exposeInt('col'),
      rowLabel: t.exposeString('rowLabel'),
      colLabel: t.exposeInt('colLabel'),
    }),
  })

// Extend BeverageType with the cellar nested field, batched by the per-request loader.
builder.objectField(BeverageType, 'cellar', (t) =>
  t.field({
    type: CellarBottleType,
    nullable: true,
    description: 'Position in the cellar grid (null if the wine is not in cellar)',
    resolve: async (wine, _, { loaders }) => (await loaders.cellar.load(wine.id)) ?? null,
  }),
)
