import { builder } from '~/domain/shared/graphql/builder'
import { BeverageTypeEnum, WineColorEnum } from './enums'

export const AddWineInput = builder.inputType('AddWineInput', {
  description: 'Manually add a beverage to the catalog',
  fields: (t) => ({
    name: t.field({ type: 'WineName', required: true }),
    beverageType: t.field({
      type: BeverageTypeEnum,
      description: 'Kind of beverage — defaults to WINE when absent',
    }),
    color: t.field({
      type: WineColorEnum,
      description: 'Wine color — required when the beverage is a wine',
    }),
    style: t.field({ type: 'BeverageStyle' }),
    alcoholContent: t.float({ description: 'Alcohol by volume (% vol)' }),
    vintage: t.field({ type: 'Year' }),
    domain: t.field({ type: 'WineDomain' }),
    appellation: t.field({ type: 'Appellation' }),
    region: t.field({ type: 'Region' }),
    country: t.field({ type: 'Country' }),
    grapeVarieties: t.stringList(),
    classification: t.field({ type: 'Classification' }),
    purchasePrice: t.field({ type: 'Eur' }),
    purchaseDate: t.string({ description: 'ISO date string' }),
    drinkFrom: t.field({ type: 'Year' }),
    drinkUntil: t.field({ type: 'Year' }),
    notes: t.string(),
    giftedBy: t.field({ type: 'PersonName' }),
    servingTemperature: t.float(),
    latitude: t.field({ type: 'Latitude' }),
    longitude: t.field({ type: 'Longitude' }),
    placeName: t.field({ type: 'PlaceName' }),
  }),
})

export const UpdateWineInput = builder.inputType('UpdateWineInput', {
  description: 'Update an existing wine. Absent fields keep their current value.',
  fields: (t) => ({
    name: t.field({ type: 'WineName' }),
    beverageType: t.field({ type: BeverageTypeEnum }),
    color: t.field({ type: WineColorEnum }),
    style: t.field({ type: 'BeverageStyle' }),
    alcoholContent: t.float({ description: 'Alcohol by volume (% vol)' }),
    vintage: t.field({ type: 'Year' }),
    domain: t.field({ type: 'WineDomain' }),
    appellation: t.field({ type: 'Appellation' }),
    region: t.field({ type: 'Region' }),
    country: t.field({ type: 'Country' }),
    grapeVarieties: t.stringList(),
    classification: t.field({ type: 'Classification' }),
    purchasePrice: t.field({ type: 'Eur' }),
    purchaseDate: t.string(),
    drinkFrom: t.field({ type: 'Year' }),
    drinkUntil: t.field({ type: 'Year' }),
    notes: t.string(),
    giftedBy: t.field({ type: 'PersonName' }),
    servingTemperature: t.float(),
    latitude: t.field({ type: 'Latitude' }),
    longitude: t.field({ type: 'Longitude' }),
    placeName: t.field({ type: 'PlaceName' }),
  }),
})
