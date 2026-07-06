import { builder } from '~/domain/shared/graphql/builder'
import { BeverageSubtypeEnum, BeverageTypeEnum, WineColorEnum } from './enums'

export const AddBeverageInput = builder.inputType('AddBeverageInput', {
  description: 'Manually add a beverage to the catalog',
  fields: (t) => ({
    name: t.field({ type: 'BeverageName', required: true }),
    beverageType: t.field({
      type: BeverageTypeEnum,
      description: 'Kind of beverage — defaults to WINE when absent',
    }),
    color: t.field({
      type: WineColorEnum,
      description: 'Beverage color — required when the beverage is a wine',
    }),
    subtype: t.field({
      type: BeverageSubtypeEnum,
      description: 'Structured subtype — must be valid for the beverage type',
    }),
    alcoholContent: t.field({ type: 'Percentage', description: 'Alcohol by volume (% vol)' }),
    vintage: t.field({ type: 'Year' }),
    producer: t.field({ type: 'Producer' }),
    appellation: t.field({ type: 'Appellation' }),
    region: t.field({ type: 'Region' }),
    country: t.field({ type: 'Country' }),
    grapeVarieties: t.field({ type: ['GrapeVariety'] }),
    classification: t.field({ type: 'Classification' }),
    purchasePrice: t.field({ type: 'Eur' }),
    purchaseDate: t.field({ type: 'DateTime' }),
    drinkFrom: t.field({ type: 'Year' }),
    drinkUntil: t.field({ type: 'Year' }),
    notes: t.field({ type: 'Notes' }),
    giftedBy: t.field({ type: 'PersonName' }),
    servingTemperature: t.field({ type: 'Celsius' }),
    latitude: t.field({ type: 'Latitude' }),
    longitude: t.field({ type: 'Longitude' }),
    placeName: t.field({ type: 'PlaceName' }),
  }),
})

export const UpdateBeverageInput = builder.inputType('UpdateBeverageInput', {
  description: 'Update an existing beverage. Absent fields keep their current value.',
  fields: (t) => ({
    name: t.field({ type: 'BeverageName' }),
    beverageType: t.field({ type: BeverageTypeEnum }),
    color: t.field({ type: WineColorEnum }),
    subtype: t.field({ type: BeverageSubtypeEnum }),
    alcoholContent: t.field({ type: 'Percentage', description: 'Alcohol by volume (% vol)' }),
    vintage: t.field({ type: 'Year' }),
    producer: t.field({ type: 'Producer' }),
    appellation: t.field({ type: 'Appellation' }),
    region: t.field({ type: 'Region' }),
    country: t.field({ type: 'Country' }),
    grapeVarieties: t.field({ type: ['GrapeVariety'] }),
    classification: t.field({ type: 'Classification' }),
    purchasePrice: t.field({ type: 'Eur' }),
    purchaseDate: t.field({ type: 'DateTime' }),
    drinkFrom: t.field({ type: 'Year' }),
    drinkUntil: t.field({ type: 'Year' }),
    notes: t.field({ type: 'Notes' }),
    giftedBy: t.field({ type: 'PersonName' }),
    servingTemperature: t.field({ type: 'Celsius' }),
    latitude: t.field({ type: 'Latitude' }),
    longitude: t.field({ type: 'Longitude' }),
    placeName: t.field({ type: 'PlaceName' }),
  }),
})
