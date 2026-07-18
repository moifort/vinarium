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
  description:
    'A Firebase Auth user identifier, carried as an opaque non-empty string.\n\n' +
    'Every beverage and satellite record is owned by a `UserId`; the viewer identity ' +
    'is derived from the request Bearer token, so this is rarely passed as an input. ' +
    'Example: "KyTjMU39NBhfakGxExfqLmC5OYU2".',
  serialize: (value) => value as string,
  parseValue: validatedParse('UserId', UserId),
})

builder.scalarType('BeverageId', {
  description:
    'The unique identifier of a `Beverage`, formatted as a UUID v4.\n\n' +
    'Serves as the primary key of a bottle and as the pagination cursor on the ' +
    '`beverages` query (the `after` argument). Example: ' +
    '"f47ac10b-58cc-4372-a567-0e02b2c3d479".',
  serialize: (value) => value as string,
  parseValue: validatedParse('BeverageId', BeverageId),
})

builder.scalarType('HouseholdId', {
  description:
    'The unique identifier of a household, formatted as a UUID v4.\n\n' +
    'A household groups members who share a cellar. Example: ' +
    '"c9bf9e57-1685-4c89-bafb-ff5af830be8a".',
  serialize: (value) => value as string,
  parseValue: validatedParse('HouseholdId', HouseholdId),
})

builder.scalarType('BeverageName', {
  description:
    'The display name of a beverage, a non-empty string.\n\n' + 'Example: "Chateau Margaux".',
  serialize: (value) => value as string,
  parseValue: validatedParse('BeverageName', BeverageName),
})

builder.scalarType('Producer', {
  description:
    'The maker of a beverage, a non-empty string: a chateau, domaine, distillery or brewery.\n\n' +
    'Example: "Domaine de la Romanee-Conti".',
  serialize: (value) => value as string,
  parseValue: validatedParse('Producer', Producer),
})

builder.scalarType('Notes', {
  description:
    'Free-form notes attached to a beverage, a non-empty string.\n\n' +
    'Personal remarks about the bottle. Example: "Bought on our trip to Bordeaux".',
  serialize: (value) => value as string,
  parseValue: validatedParse('Notes', Notes),
})

builder.scalarType('Appellation', {
  description:
    'The appellation of a wine, a non-empty string (AOC, AOP, DOC and similar).\n\n' +
    'Example: "Saint-Emilion Grand Cru".',
  serialize: (value) => value as string,
  parseValue: validatedParse('Appellation', Appellation),
})

builder.scalarType('Classification', {
  description:
    'The official classification of a wine, a non-empty string.\n\n' +
    'Example: "Premier Grand Cru Classe".',
  serialize: (value) => value as string,
  parseValue: validatedParse('Classification', Classification),
})

builder.scalarType('GrapeVariety', {
  description:
    'A single grape variety (cepage), a non-empty string.\n\n' +
    'A wine carries a list of these. Example: "Cabernet Sauvignon".',
  serialize: (value) => value as string,
  parseValue: validatedParse('GrapeVariety', GrapeVariety),
})

builder.scalarType('Celsius', {
  description:
    'A temperature in degrees Celsius, a number between -50 and 100.\n\n' +
    'Used for a wine serving temperature. Example: 16.',
  serialize: (value) => value as number,
  parseValue: validatedParse('Celsius', Celsius),
})

builder.scalarType('Country', {
  description:
    'A country name, a non-empty string.\n\n' +
    'The country a beverage comes from. Example: "France".',
  serialize: (value) => value as string,
  parseValue: validatedParse('Country', Country),
})

builder.scalarType('Region', {
  description: 'A wine region, a non-empty string.\n\n' + 'Example: "Bourgogne".',
  serialize: (value) => value as string,
  parseValue: validatedParse('Region', Region),
})

builder.scalarType('PersonName', {
  description:
    'A person name, a string of 1 to 200 characters.\n\n' +
    'Used for a gift giver or a household member display name. Example: "Marie Dupont".',
  serialize: (value) => value as string,
  parseValue: validatedParse('PersonName', PersonName),
})

builder.scalarType('PlaceName', {
  description:
    'A place name, a string of 1 to 200 characters.\n\n' +
    'The name of the shop or place where a bottle was bought. Example: "La Cave du Marais".',
  serialize: (value) => value as string,
  parseValue: validatedParse('PlaceName', PlaceName),
})

builder.scalarType('Year', {
  description:
    'A calendar year, an integer greater than or equal to 1800.\n\n' +
    'Used for a wine vintage and for the bounds of a drink window. Example: 2016.',
  serialize: (value) => value as number,
  parseValue: validatedParse('Year', Year),
})

builder.scalarType('Eur', {
  description:
    'An amount in euros, a non-negative number.\n\n' +
    'Used for a bottle purchase price. Example: 24.9.',
  serialize: (value) => value as number,
  parseValue: validatedParse('Eur', Eur),
})

builder.scalarType('Percentage', {
  description:
    'A percentage, a number between 0 and 100.\n\n' +
    'Used for alcohol content by volume. Example: 13.5.',
  serialize: (value) => value as number,
  parseValue: validatedParse('Percentage', Percentage),
})

builder.scalarType('Latitude', {
  description:
    'A geographic latitude in decimal degrees, a number between -90 and 90.\n\n' +
    'Part of the coordinates of a purchase place. Example: 44.8378.',
  serialize: (value) => value as number,
  parseValue: validatedParse('Latitude', Latitude),
})

builder.scalarType('Longitude', {
  description:
    'A geographic longitude in decimal degrees, a number between -180 and 180.\n\n' +
    'Part of the coordinates of a purchase place. Example: -0.5792.',
  serialize: (value) => value as number,
  parseValue: validatedParse('Longitude', Longitude),
})

builder.scalarType('Rating', {
  description:
    'A tasting rating, an integer from 1 to 5 (star rating).\n\n' +
    'Set on a consumed beverage. Example: 4.',
  serialize: (value) => value as number,
  parseValue: validatedParse('Rating', Rating),
})
