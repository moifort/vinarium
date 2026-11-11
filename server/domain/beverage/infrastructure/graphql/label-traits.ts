import { builder } from '~/domain/shared/graphql/builder'
import type { LabelTraits } from '../../types'

export const LabelTypefaceEnum = builder.enumType('LabelTypeface', {
  description: 'The family of type the name on a label is set in.',
  values: {
    DIDONE: { value: 'didone', description: 'High-contrast serif, as Didot or Bodoni' },
    GARALDE: { value: 'garalde', description: 'Classic serif, as Baskerville or Garamond' },
    SCRIPT: { value: 'script', description: 'Joined, calligraphic script' },
    GEOMETRIC_SANS: { value: 'geometric-sans', description: 'Geometric sans, as Futura' },
    HUMANIST_SANS: { value: 'humanist-sans', description: 'Humanist sans, as Gill Sans or Optima' },
    SLAB: { value: 'slab', description: 'Slab serif, square-ended serifs' },
    BLACKLETTER: { value: 'blackletter', description: 'Gothic blackletter' },
    HAND: { value: 'hand', description: 'Hand-drawn or hand-written lettering' },
  } as const,
})

export const LabelEmblemEnum = builder.enumType('LabelEmblem', {
  description: 'The main picture a label carries, if any.',
  values: {
    CASTLE: { value: 'castle', description: 'A château or a building' },
    CREST: { value: 'crest', description: 'A coat of arms, a shield or a monogram' },
    KEYS: { value: 'keys', description: 'Crossed keys' },
    GRAPES: { value: 'grapes', description: 'A bunch of grapes or vine leaves' },
    MOUNTAINS: { value: 'mountains', description: 'Hills or mountains' },
    SUN: { value: 'sun', description: 'A sun' },
    STARS: { value: 'stars', description: 'Stars' },
    ILLUSTRATION: { value: 'illustration', description: 'Any other drawing: an animal, a figure' },
    NONE: { value: 'none', description: 'Type only, no picture' },
  } as const,
})

export const LabelShapeEnum = builder.enumType('LabelShape', {
  description: 'The outline of the label.',
  values: {
    PORTRAIT: { value: 'portrait', description: 'A rectangle taller than wide' },
    LANDSCAPE: { value: 'landscape', description: 'A rectangle wider than tall' },
    SQUARE: { value: 'square', description: 'A square' },
    OVAL: { value: 'oval', description: 'An oval or a circle' },
    SHIELD: { value: 'shield', description: 'A shield or an arched top' },
    IRREGULAR: { value: 'irregular', description: 'A cut-out or free shape' },
  } as const,
})

export const LabelTraitsType = builder.objectRef<LabelTraits>('LabelTraits').implement({
  description:
    "What a bottle's label looks like, as the scan reads it off the photo.\n\n" +
    'The app draws the bottle with the closest of its label looks. Absent on a beverage ' +
    'added by hand, named in words, or scanned before the scan read it.',
  fields: (t) => ({
    paper: t.expose('paper', { type: 'HexColor', description: 'Colour of the paper' }),
    ink: t.expose('ink', { type: 'HexColor', description: 'Colour of the main text' }),
    accent: t.expose('accent', {
      type: 'HexColor',
      nullable: true,
      description: 'Second colour of the type or ornaments, when there is one',
    }),
    metallic: t.exposeBoolean('metallic', { description: 'Gold, silver or foil printing' }),
    typeface: t.expose('typeface', {
      type: LabelTypefaceEnum,
      description: 'Type of the name',
    }),
    capitals: t.exposeBoolean('capitals', { description: 'The name set in capitals' }),
    frame: t.exposeBoolean('frame', { description: 'A drawn frame or border' }),
    band: t.exposeBoolean('band', { description: 'A coloured band across the label' }),
    emblem: t.expose('emblem', { type: LabelEmblemEnum, description: 'Main picture' }),
    shape: t.expose('shape', { type: LabelShapeEnum, description: 'Outline of the label' }),
  }),
})

export const LabelTraitsInput = builder.inputType('LabelTraitsInput', {
  description: 'What the label looks like, passed on from the scan result as it came.',
  fields: (t) => ({
    paper: t.field({ type: 'HexColor', required: true, description: 'Colour of the paper' }),
    ink: t.field({ type: 'HexColor', required: true, description: 'Colour of the main text' }),
    accent: t.field({ type: 'HexColor', description: 'Second colour, when there is one' }),
    metallic: t.boolean({ required: true, description: 'Gold, silver or foil printing' }),
    typeface: t.field({ type: LabelTypefaceEnum, required: true, description: 'Type of the name' }),
    capitals: t.boolean({ required: true, description: 'The name set in capitals' }),
    frame: t.boolean({ required: true, description: 'A drawn frame or border' }),
    band: t.boolean({ required: true, description: 'A coloured band across the label' }),
    emblem: t.field({ type: LabelEmblemEnum, required: true, description: 'Main picture' }),
    shape: t.field({ type: LabelShapeEnum, required: true, description: 'Outline of the label' }),
  }),
})
