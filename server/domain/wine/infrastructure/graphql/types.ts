import { builder } from '~/domain/shared/graphql/builder'
import type { Wine } from '../../types'
import { WineColorEnum } from './enums'

export const WineType = builder.objectRef<Wine>('Wine').implement({
  description: 'A wine in the user’s collection',
  fields: (t) => ({
    id: t.expose('id', { type: 'WineId' }),
    userId: t.expose('userId', { type: 'UserId' }),
    name: t.expose('name', { type: 'WineName' }),
    color: t.expose('color', { type: WineColorEnum }),
    vintage: t.expose('vintage', { type: 'Year', nullable: true }),
    domain: t.expose('domain', { type: 'WineDomain', nullable: true }),
    appellation: t.expose('appellation', { type: 'Appellation', nullable: true }),
    region: t.expose('region', { type: 'Region', nullable: true }),
    country: t.expose('country', { type: 'Country', nullable: true }),
    grapeVarieties: t.exposeStringList('grapeVarieties', { nullable: true }),
    classification: t.expose('classification', { type: 'Classification', nullable: true }),
    purchasePrice: t.expose('purchasePrice', { type: 'Eur', nullable: true }),
    purchaseDate: t.exposeString('purchaseDate', { nullable: true }),
    drinkFrom: t.expose('drinkFrom', { type: 'Year', nullable: true }),
    drinkUntil: t.expose('drinkUntil', { type: 'Year', nullable: true }),
    notes: t.exposeString('notes', { nullable: true }),
    giftedBy: t.expose('giftedBy', { type: 'PersonName', nullable: true }),
    servingTemperature: t.exposeFloat('servingTemperature', { nullable: true }),
    latitude: t.expose('latitude', { type: 'Latitude', nullable: true }),
    longitude: t.expose('longitude', { type: 'Longitude', nullable: true }),
    placeName: t.expose('placeName', { type: 'PlaceName', nullable: true }),
    createdAt: t.expose('createdAt', { type: 'DateTime' }),
    updatedAt: t.expose('updatedAt', { type: 'DateTime' }),
  }),
})
