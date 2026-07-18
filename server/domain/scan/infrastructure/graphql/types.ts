import {
  BeverageSubtypeEnum,
  BeverageTypeEnum,
  WineColorEnum,
} from '~/domain/beverage/infrastructure/graphql/enums'
import { builder } from '~/domain/shared/graphql/builder'
import type { ScanResult } from '../../types'

export const ScanResultType = builder.objectRef<ScanResult>('ScanResult').implement({
  description:
    'Structured beverage details extracted by AI from a bottle-label image.\n\n' +
    'Produced by `scanBeverage`: the label photo is read by a vision model (Gemini) ' +
    'and, when a beverage is identified, enriched with a web search. All fields except ' +
    '`recognized`, `name` and `beverageType` are best-effort and may be null. Check `recognized` ' +
    'first: when false the extraction failed to identify a beverage and the other fields are ' +
    'placeholders, so the client should show a "no result" screen instead of a review form.\n\n' +
    '```graphql\n' +
    'mutation {\n' +
    '  scanBeverage(imageBase64: "<jpeg-base64>") {\n' +
    '    recognized\n' +
    '    name\n' +
    '    beverageType\n' +
    '    color\n' +
    '    vintage\n' +
    '    appellation\n' +
    '    estimatedPrice\n' +
    '  }\n' +
    '}\n' +
    '```',
  fields: (t) => ({
    recognized: t.exposeBoolean('recognized', {
      description:
        'True when a beverage label was identified. False signals the client to show the ' +
        '"no result" screen; the remaining fields are then meaningless placeholders.',
    }),
    name: t.exposeString('name', {
      description: 'Beverage name read from the label; empty string when not recognized',
    }),
    beverageType: t.expose('beverageType', {
      type: BeverageTypeEnum,
      description: 'Detected beverage family (wine, spirit, beer, ...); defaults to wine',
    }),
    color: t.expose('color', {
      type: WineColorEnum,
      nullable: true,
      description: 'Wine color (red, white, rose); null for non-wine beverages',
    }),
    subtype: t.expose('subtype', {
      type: BeverageSubtypeEnum,
      nullable: true,
      description: 'Structured subtype consistent with the beverage type; null when uncertain',
    }),
    alcoholContent: t.exposeFloat('alcoholContent', {
      nullable: true,
      description: 'Alcohol by volume in percent; null when not visible or estimable',
    }),
    domain: t.exposeString('domain', {
      nullable: true,
      description: 'Producer (domain, distillery, brewery or kura); null when unknown',
    }),
    vintage: t.exposeInt('vintage', {
      nullable: true,
      description: 'Vintage year read from the label; null when absent',
    }),
    appellation: t.exposeString('appellation', {
      nullable: true,
      description: 'Appellation (e.g. Bordeaux, Bourgogne); null when unknown',
    }),
    region: t.exposeString('region', {
      nullable: true,
      description: 'Production region; null when unknown',
    }),
    country: t.exposeString('country', {
      nullable: true,
      description: 'Country of origin; null when unknown',
    }),
    grapeVarieties: t.exposeStringList('grapeVarieties', {
      nullable: true,
      description: 'Grape varieties mentioned; null or empty when none identified',
    }),
    classification: t.exposeString('classification', {
      nullable: true,
      description: 'Official classification (e.g. Grand Cru, AOC, IGP); null when unknown',
    }),
    drinkFrom: t.exposeInt('drinkFrom', {
      nullable: true,
      description: 'Estimated first year the wine can be enjoyed; null when not estimable',
    }),
    drinkUntil: t.exposeInt('drinkUntil', {
      nullable: true,
      description: 'Estimated last year the wine should be drunk; null when not estimable',
    }),
    estimatedPrice: t.exposeFloat('estimatedPrice', {
      nullable: true,
      description: 'Estimated market price in euros; null when not estimable',
    }),
  }),
})
