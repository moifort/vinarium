import { builder } from '~/domain/shared/graphql/builder'
import { WineType } from '~/domain/wine/infrastructure/graphql/types'
import { CellarQuery } from '../../query'
import type { CellarBottle, CellarBottleView } from '../../types'

export const CellarBottleType = builder.objectRef<CellarBottleView>('CellarBottle').implement({
  description: 'A bottle physically placed in the cellar grid',
  fields: (t) => ({
    wineId: t.expose('wineId', { type: 'WineId' }),
    row: t.exposeInt('row'),
    col: t.exposeInt('col'),
    rowLabel: t.exposeString('rowLabel'),
    colLabel: t.exposeInt('colLabel'),
    createdAt: t.expose('createdAt', { type: 'DateTime' }),
    updatedAt: t.expose('updatedAt', { type: 'DateTime' }),
  }),
})

export const CellarBottleWithWineType = builder
  .objectRef<CellarBottleView & { wine: import('~/domain/wine/types').Wine }>(
    'CellarBottleWithWine',
  )
  .implement({
    description: 'A cellar bottle joined with the corresponding wine',
    fields: (t) => ({
      wineId: t.expose('wineId', { type: 'WineId' }),
      row: t.exposeInt('row'),
      col: t.exposeInt('col'),
      rowLabel: t.exposeString('rowLabel'),
      colLabel: t.exposeInt('colLabel'),
      createdAt: t.expose('createdAt', { type: 'DateTime' }),
      wine: t.field({ type: WineType, resolve: (b) => b.wine }),
    }),
  })

export const CellarBottlesType = builder
  .objectRef<{
    items: (CellarBottleView & { wine: import('~/domain/wine/types').Wine })[]
    hasMore: boolean
  }>('CellarBottles')
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

// Extend WineType with the cellar nested field
builder.objectField(WineType, 'cellar', (t) =>
  t.field({
    type: CellarBottleType,
    nullable: true,
    description: 'Position in the cellar grid (null if the wine is not in cellar)',
    resolve: async (wine, _, { userId }) => {
      if (wine.cellar !== undefined) return wine.cellar
      const bottle = await CellarQuery.getBottleByWineId(userId, wine.id)
      return bottle === 'not-found' ? null : bottle
    },
  }),
)
