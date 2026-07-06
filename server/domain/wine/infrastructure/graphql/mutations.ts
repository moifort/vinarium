import { GraphQLError } from 'graphql'
import { builder } from '~/domain/shared/graphql/builder'
import { stripNulls } from '~/utils/input'
import { WineCommand } from '../../command'
import type { Wine } from '../../types'
import { WineUseCase } from '../../use-case'
import { AddWineInput, UpdateWineInput } from './inputs'
import { WineType } from './types'

// Drop null/undefined entries; return undefined if nothing survives — so an
// all-empty sub-object never reaches Firestore (which rejects undefined values).
const compact = <T extends Record<string, unknown>>(obj: T): T | undefined => {
  const cleaned = Object.fromEntries(
    Object.entries(obj).filter(([, value]) => value !== undefined && value !== null),
  ) as T
  return Object.keys(cleaned).length > 0 ? cleaned : undefined
}

// The flat purchase/drink-window/place input fields, regrouped into the wine
// aggregate's sub-objects. A sub-object with no set field is simply absent.
type WineFlatInput = {
  drinkFrom?: unknown
  drinkUntil?: unknown
  purchasePrice?: unknown
  purchaseDate?: unknown
  latitude?: unknown
  longitude?: unknown
  placeName?: unknown
}

const subObjects = (input: WineFlatInput): Pick<Wine, 'drinkWindow' | 'purchase' | 'place'> => {
  const out: Pick<Wine, 'drinkWindow' | 'purchase' | 'place'> = {}
  const drinkWindow = compact({ from: input.drinkFrom, until: input.drinkUntil })
  if (drinkWindow) out.drinkWindow = drinkWindow as Wine['drinkWindow']
  const purchase = compact({ price: input.purchasePrice, date: input.purchaseDate })
  if (purchase) out.purchase = purchase as Wine['purchase']
  const place = compact({
    latitude: input.latitude,
    longitude: input.longitude,
    name: input.placeName,
  })
  if (place) out.place = place as Wine['place']
  return out
}

builder.mutationField('addWine', (t) =>
  t.field({
    type: WineType,
    description: 'Add a new beverage to the catalog',
    args: { input: t.arg({ type: AddWineInput, required: true }) },
    resolve: async (_root, { input }, { userId }) => {
      const {
        name,
        beverageType,
        drinkFrom,
        drinkUntil,
        purchasePrice,
        purchaseDate,
        latitude,
        longitude,
        placeName,
        ...scalars
      } = stripNulls(input)
      const data = { ...scalars, ...subObjects(input) }
      const result = await WineCommand.add(userId, name, beverageType ?? 'wine', data)
      if (result === 'color-required')
        throw new GraphQLError('A wine requires a color', {
          extensions: { code: 'BAD_USER_INPUT' },
        })
      if (result === 'subtype-invalid')
        throw new GraphQLError('This subtype does not fit the beverage type', {
          extensions: { code: 'BAD_USER_INPUT' },
        })
      return result
    },
  }),
)

builder.mutationField('updateWine', (t) =>
  t.field({
    type: WineType,
    description: 'Update an existing wine',
    args: {
      id: t.arg({ type: 'WineId', required: true }),
      input: t.arg({ type: UpdateWineInput, required: true }),
    },
    resolve: async (_root, { id, input }, { userId }) => {
      const {
        drinkFrom,
        drinkUntil,
        purchasePrice,
        purchaseDate,
        latitude,
        longitude,
        placeName,
        ...scalars
      } = stripNulls(input)
      const data = { ...scalars, ...subObjects(input) }
      const result = await WineCommand.update(userId, id, data)
      if (result === 'not-found')
        throw new GraphQLError('Wine not found', { extensions: { code: 'NOT_FOUND' } })
      if (result === 'color-required')
        throw new GraphQLError('A wine requires a color', {
          extensions: { code: 'BAD_USER_INPUT' },
        })
      if (result === 'subtype-invalid')
        throw new GraphQLError('This subtype does not fit the beverage type', {
          extensions: { code: 'BAD_USER_INPUT' },
        })
      return result
    },
  }),
)

builder.mutationField('deleteWine', (t) =>
  t.field({
    type: 'Boolean',
    description:
      'Delete a wine and all related data (cellar, tasting, gift, recommendation, journal)',
    args: { id: t.arg({ type: 'WineId', required: true }) },
    resolve: async (_root, { id }, { userId }) => {
      const result = await WineUseCase.removeCompletely(userId, id)
      if (result === 'not-found')
        throw new GraphQLError('Wine not found', { extensions: { code: 'NOT_FOUND' } })
      return true
    },
  }),
)
