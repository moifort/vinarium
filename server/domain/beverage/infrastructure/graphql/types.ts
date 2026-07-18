import { HouseholdQuery } from '~/domain/household/query'
import { builder } from '~/domain/shared/graphql/builder'
import type { Beverage, DrinkWindow, Place, Purchase, WineDetails } from '../../types'
import { BeverageSubtypeEnum, BeverageTypeEnum, WineColorEnum } from './enums'

const DrinkWindowType = builder.objectRef<DrinkWindow>('DrinkWindow').implement({
  description:
    'The span of years during which a wine is at its best.\n\n' +
    'Either bound may stand alone: a wine to drink from 2028 with no upper bound, or ' +
    'before 2030 with no lower one.',
  fields: (t) => ({
    from: t.expose('from', {
      type: 'Year',
      nullable: true,
      description: 'First year the wine is ready to drink; null when open-ended',
    }),
    until: t.expose('until', {
      type: 'Year',
      nullable: true,
      description: 'Last year the wine is still at its best; null when open-ended',
    }),
  }),
})

const PurchaseType = builder.objectRef<Purchase>('Purchase').implement({
  description:
    'What a bottle cost and when it was acquired.\n\n' +
    'Both fields are optional and independent.',
  fields: (t) => ({
    price: t.expose('price', {
      type: 'Eur',
      nullable: true,
      description: 'The price paid for the bottle, in euros',
    }),
    date: t.expose('date', {
      type: 'DateTime',
      nullable: true,
      description: 'The date the bottle was acquired',
    }),
  }),
})

const PlaceType = builder.objectRef<Place>('Place').implement({
  description:
    'Where a bottle was bought.\n\n' +
    'A coordinate pair always travels together; the place name may exist without ' +
    'coordinates (a shop typed by hand) and vice versa.',
  fields: (t) => ({
    latitude: t.expose('latitude', {
      type: 'Latitude',
      nullable: true,
      description: 'Latitude of the purchase place; paired with longitude',
    }),
    longitude: t.expose('longitude', {
      type: 'Longitude',
      nullable: true,
      description: 'Longitude of the purchase place; paired with latitude',
    }),
    name: t.expose('name', {
      type: 'PlaceName',
      nullable: true,
      description: 'Name of the shop or place of purchase',
    }),
  }),
})

// The wine-only fields, exposed as one member of the BeverageDetails union.
const WineDetailsType = builder.objectRef<WineDetails>('WineDetails').implement({
  description:
    'The fields that belong to a wine and to no other beverage type.\n\n' +
    'Reached through the `details` union on a `Beverage`, non-null only when the ' +
    'beverage type is `WINE`.',
  fields: (t) => ({
    color: t.expose('color', {
      type: WineColorEnum,
      nullable: true,
      description: 'Wine color (red, white, rose)',
    }),
    vintage: t.expose('vintage', {
      type: 'Year',
      nullable: true,
      description: 'Harvest year of the wine',
    }),
    appellation: t.expose('appellation', {
      type: 'Appellation',
      nullable: true,
      description: 'Appellation of the wine',
    }),
    classification: t.expose('classification', {
      type: 'Classification',
      nullable: true,
      description: 'Official classification of the wine',
    }),
    grapeVarieties: t.expose('grapeVarieties', {
      type: ['GrapeVariety'],
      nullable: true,
      description: 'Grape varieties (cepages) that make up the wine',
    }),
    drinkWindow: t.field({
      type: DrinkWindowType,
      nullable: true,
      description: 'Years the wine is at its best to drink',
      resolve: (w) => w.drinkWindow,
    }),
    servingTemperature: t.expose('servingTemperature', {
      type: 'Celsius',
      nullable: true,
      description: 'Recommended serving temperature, in degrees Celsius',
    }),
  }),
})

// The per-type details union. Only wine has a member for now; adding BeerDetails
// is a new member plus a branch in resolveType (keyed on the parent's type).
const BeverageDetailsUnion = builder.unionType('BeverageDetails', {
  description:
    'The fields that exist only for a specific beverage type.\n\n' +
    'A union so each beverage type can contribute its own detail object. Only ' +
    '`WineDetails` is a member today; other types resolve `details` to null.',
  types: [WineDetailsType],
  resolveType: () => 'WineDetails',
})

// The satellite fields (cellar, consumption, gift, recommendation, history) are
// grafted onto BeverageType by their own domains via builder.objectField and
// resolve through the per-request loaders — a Beverage stays a plain Beverage here.
export const BeverageType = builder.objectRef<Beverage>('Beverage').implement({
  description:
    'A beverage in a collection (wine, spirit, beer, sake, cider or other), the ' +
    'aggregate root of the schema.\n\n' +
    'The base fields (name, producer, region, purchase, ...) live here. Type-specific ' +
    'fields hang off the `details` union, non-null only for a wine.\n\n' +
    'Other domains graft SATELLITE fields onto this type through `builder.objectField`: ' +
    '`cellar` (the physical slot), `consumption` (tasting note and favorite flag), ' +
    '`gift` (given or received), `recommendation` (who recommended it) and `history` ' +
    '(the journal of cellar movements). Those fields are defined in their own domains, ' +
    'not here, and resolve through per-request DataLoaders so selecting them across a ' +
    'page of beverages never triggers an N+1 read.\n\n' +
    '```graphql\n' +
    'query {\n' +
    '  beverage(id: "f47ac10b-58cc-4372-a567-0e02b2c3d479") {\n' +
    '    name\n' +
    '    cellar { position }\n' +
    '    consumption { rating favorite }\n' +
    '  }\n' +
    '}\n' +
    '```',
  fields: (t) => ({
    id: t.expose('id', { type: 'BeverageId', description: 'Unique identifier of the beverage' }),
    userId: t.expose('userId', {
      type: 'UserId',
      description: 'Identifier of the user who owns the beverage',
    }),
    isMine: t.boolean({
      description: 'Whether this beverage belongs to the viewer (false for a housemate bottle)',
      resolve: (beverage, _args, { userId }) => beverage.userId === userId,
    }),
    ownerName: t.field({
      type: 'PersonName',
      nullable: true,
      description:
        'Display name of the household member who owns this beverage; null when it is the viewer own',
      resolve: async (beverage, _args, { userId }) => {
        if (beverage.userId === userId) return null
        const scope = await HouseholdQuery.cellarScope(userId)
        return scope.displayNames.get(beverage.userId) ?? null
      },
    }),
    name: t.expose('name', { type: 'BeverageName', description: 'Display name of the beverage' }),
    beverageType: t.expose('beverageType', {
      type: BeverageTypeEnum,
      description: 'Kind of beverage; the discriminant that governs subtype and details',
    }),
    subtype: t.expose('subtype', {
      type: BeverageSubtypeEnum,
      nullable: true,
      description: 'Structured subtype, valid for this beverage type',
    }),
    alcoholContent: t.expose('alcoholContent', {
      type: 'Percentage',
      nullable: true,
      description: 'Alcohol content by volume, in percent',
    }),
    producer: t.expose('producer', {
      type: 'Producer',
      nullable: true,
      description: 'Maker of the beverage (chateau, domaine, distillery, brewery)',
    }),
    region: t.expose('region', {
      type: 'Region',
      nullable: true,
      description: 'Region the beverage comes from',
    }),
    country: t.expose('country', {
      type: 'Country',
      nullable: true,
      description: 'Country the beverage comes from',
    }),
    purchase: t.field({
      type: PurchaseType,
      nullable: true,
      description: 'What the bottle cost and when it was acquired',
      resolve: (b) => b.purchase,
    }),
    notes: t.expose('notes', {
      type: 'Notes',
      nullable: true,
      description: 'Free-form personal notes about the beverage',
    }),
    place: t.field({
      type: PlaceType,
      nullable: true,
      description: 'Where the bottle was bought',
      resolve: (b) => b.place,
    }),
    details: t.field({
      type: BeverageDetailsUnion,
      nullable: true,
      description: 'Type-specific fields; non-null only for a wine',
      resolve: (b) => (b.beverageType === 'wine' ? b.wine : null),
    }),
    createdAt: t.expose('createdAt', {
      type: 'DateTime',
      description: 'When the beverage was added to the collection',
    }),
    updatedAt: t.expose('updatedAt', {
      type: 'DateTime',
      description: 'When the beverage was last changed',
    }),
  }),
})

// Paginated beverage list payload: the page of items plus the cursor-less
// pagination signals (façon pchook). `totalCount` is the page size when unknown.
export type BeveragesPage = { items: Beverage[]; hasMore: boolean; totalCount: number }

export const BeveragesType = builder.objectRef<BeveragesPage>('Beverages').implement({
  description:
    'A single page of the beverage list.\n\n' +
    'Cursor-less pagination: the page carries its items plus a `hasMore` signal. To ' +
    'fetch the next page, pass the id of the last item as the `after` argument of the ' +
    '`beverages` query.',
  fields: (t) => ({
    items: t.field({
      type: [BeverageType],
      description: 'The beverages on this page',
      resolve: ({ items }) => items,
    }),
    hasMore: t.exposeBoolean('hasMore', {
      description: 'Whether more beverages are available after this page',
    }),
    totalCount: t.exposeInt('totalCount', {
      description: 'Number of beverages in this page; the full collection count is not computed',
    }),
  }),
})
