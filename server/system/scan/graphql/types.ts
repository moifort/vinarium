import { builder } from '~/domain/shared/graphql/builder'
import { WineColorEnum } from '~/domain/wine/infrastructure/graphql/enums'
import type { ScanResult } from '../types'

export const ScanResultType = builder.objectRef<ScanResult>('ScanResult').implement({
  description: 'Structured wine info extracted from a label image (Claude + Gemini).',
  fields: (t) => ({
    name: t.exposeString('name'),
    color: t.expose('color', { type: WineColorEnum }),
    domain: t.exposeString('domain', { nullable: true }),
    vintage: t.exposeInt('vintage', { nullable: true }),
    appellation: t.exposeString('appellation', { nullable: true }),
    region: t.exposeString('region', { nullable: true }),
    country: t.exposeString('country', { nullable: true }),
    grapeVarieties: t.exposeStringList('grapeVarieties', { nullable: true }),
    classification: t.exposeString('classification', { nullable: true }),
    drinkFrom: t.exposeInt('drinkFrom', { nullable: true }),
    drinkUntil: t.exposeInt('drinkUntil', { nullable: true }),
    estimatedPrice: t.exposeFloat('estimatedPrice', { nullable: true }),
  }),
})
