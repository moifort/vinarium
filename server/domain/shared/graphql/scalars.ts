import { GraphQLError } from 'graphql'
import { ZodError } from 'zod'
import {
  Appellation,
  BeverageId,
  BeverageName,
  Celsius,
  Classification,
  GrapeVariety,
  Notes,
  Producer,
} from '~/domain/beverage/primitives'
import { HouseholdId } from '~/domain/household/primitives'
import {
  Country,
  Eur,
  Latitude,
  Longitude,
  Percentage,
  PersonName,
  PlaceName,
  Region,
  UserId,
  Year,
} from '~/domain/shared/primitives'
import { Rating } from '~/domain/tasting/primitives'
import { builder } from './builder'

const validatedParse =
  <T>(name: string, parse: (value: unknown) => T) =>
  (value: unknown): T => {
    try {
      return parse(value)
    } catch (error) {
      const message =
        error instanceof ZodError
          ? error.issues.map(({ message }) => message).join(', ')
          : `Invalid ${name}`
      throw new GraphQLError(`Invalid value for ${name}: ${message}`, {
        extensions: { code: 'BAD_USER_INPUT' },
      })
    }
  }

builder.scalarType('UserId', {
  description: 'Firebase Auth user identifier',
  serialize: (value) => value as string,
  parseValue: validatedParse('UserId', UserId),
})

builder.scalarType('BeverageId', {
  description: 'Beverage unique identifier (UUID v4)',
  serialize: (value) => value as string,
  parseValue: validatedParse('BeverageId', BeverageId),
})

builder.scalarType('HouseholdId', {
  description: 'Household unique identifier (UUID v4)',
  serialize: (value) => value as string,
  parseValue: validatedParse('HouseholdId', HouseholdId),
})

builder.scalarType('BeverageName', {
  description: 'Beverage display name (non-empty)',
  serialize: (value) => value as string,
  parseValue: validatedParse('BeverageName', BeverageName),
})

builder.scalarType('Producer', {
  description: 'Beverage producer / château / domaine / distillery / brewery',
  serialize: (value) => value as string,
  parseValue: validatedParse('Producer', Producer),
})

builder.scalarType('Notes', {
  description: 'Free-form tasting notes',
  serialize: (value) => value as string,
  parseValue: validatedParse('Notes', Notes),
})

builder.scalarType('Appellation', {
  description: 'Beverage appellation (AOC / AOP / DOC ...)',
  serialize: (value) => value as string,
  parseValue: validatedParse('Appellation', Appellation),
})

builder.scalarType('Classification', {
  description: 'Beverage classification (Grand Cru, Premier Cru ...)',
  serialize: (value) => value as string,
  parseValue: validatedParse('Classification', Classification),
})

builder.scalarType('GrapeVariety', {
  description: 'A grape variety (cépage)',
  serialize: (value) => value as string,
  parseValue: validatedParse('GrapeVariety', GrapeVariety),
})

builder.scalarType('Celsius', {
  description: 'A temperature in degrees Celsius',
  serialize: (value) => value as number,
  parseValue: validatedParse('Celsius', Celsius),
})

builder.scalarType('Country', {
  description: 'Country name',
  serialize: (value) => value as string,
  parseValue: validatedParse('Country', Country),
})

builder.scalarType('Region', {
  description: 'Beverage region (e.g. Bordeaux, Bourgogne)',
  serialize: (value) => value as string,
  parseValue: validatedParse('Region', Region),
})

builder.scalarType('PersonName', {
  description: 'Person name (1-200 chars)',
  serialize: (value) => value as string,
  parseValue: validatedParse('PersonName', PersonName),
})

builder.scalarType('PlaceName', {
  description: 'Place name (1-200 chars)',
  serialize: (value) => value as string,
  parseValue: validatedParse('PlaceName', PlaceName),
})

builder.scalarType('Year', {
  description: 'Calendar year (>= 1800)',
  serialize: (value) => value as number,
  parseValue: validatedParse('Year', Year),
})

builder.scalarType('Eur', {
  description: 'Euro amount (non-negative)',
  serialize: (value) => value as number,
  parseValue: validatedParse('Eur', Eur),
})

builder.scalarType('Percentage', {
  description: 'A percentage (0..100)',
  serialize: (value) => value as number,
  parseValue: validatedParse('Percentage', Percentage),
})

builder.scalarType('Latitude', {
  description: 'Latitude (-90..90)',
  serialize: (value) => value as number,
  parseValue: validatedParse('Latitude', Latitude),
})

builder.scalarType('Longitude', {
  description: 'Longitude (-180..180)',
  serialize: (value) => value as number,
  parseValue: validatedParse('Longitude', Longitude),
})

builder.scalarType('Rating', {
  description: 'Rating (1-5)',
  serialize: (value) => value as number,
  parseValue: validatedParse('Rating', Rating),
})
