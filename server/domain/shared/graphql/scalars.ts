import { GraphQLError } from 'graphql'
import { ZodError } from 'zod'
import {
  Country,
  Eur,
  Latitude,
  Longitude,
  PersonName,
  PlaceName,
  Region,
  UserId,
  Year,
} from '~/domain/shared/primitives'
import { Rating } from '~/domain/tasting/primitives'
import {
  Appellation,
  BeverageStyle,
  Classification,
  WineDomain,
  WineId,
  WineName,
} from '~/domain/wine/primitives'
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

builder.scalarType('WineId', {
  description: 'Wine unique identifier (UUID v4)',
  serialize: (value) => value as string,
  parseValue: validatedParse('WineId', WineId),
})

builder.scalarType('WineName', {
  description: 'Wine display name (non-empty)',
  serialize: (value) => value as string,
  parseValue: validatedParse('WineName', WineName),
})

builder.scalarType('WineDomain', {
  description: 'Wine producer / château / domain',
  serialize: (value) => value as string,
  parseValue: validatedParse('WineDomain', WineDomain),
})

builder.scalarType('BeverageStyle', {
  description: 'Beverage style for non-wine drinks (IPA, Single Malt, Junmai ...)',
  serialize: (value) => value as string,
  parseValue: validatedParse('BeverageStyle', BeverageStyle),
})

builder.scalarType('Appellation', {
  description: 'Wine appellation (AOC / AOP / DOC ...)',
  serialize: (value) => value as string,
  parseValue: validatedParse('Appellation', Appellation),
})

builder.scalarType('Classification', {
  description: 'Wine classification (Grand Cru, Premier Cru ...)',
  serialize: (value) => value as string,
  parseValue: validatedParse('Classification', Classification),
})

builder.scalarType('Country', {
  description: 'Country name',
  serialize: (value) => value as string,
  parseValue: validatedParse('Country', Country),
})

builder.scalarType('Region', {
  description: 'Wine region (e.g. Bordeaux, Bourgogne)',
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
