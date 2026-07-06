import SchemaBuilder from '@pothos/core'
import { GraphQLScalarType } from 'graphql'
import type { H3Event } from 'h3'
import type {
  Country,
  Eur,
  Latitude,
  Longitude,
  PersonName,
  PlaceName,
  Region,
  UserId,
  Year,
} from '~/domain/shared/types'
import type { Rating } from '~/domain/tasting/types'
import type { Appellation, Classification, WineDomain, WineId, WineName } from '~/domain/wine/types'
import type { WineSatelliteLoaders } from './loaders'

export type GraphQLContext = {
  event: H3Event
  userId: UserId
  loaders: WineSatelliteLoaders
}

const DateTimeScalar = new GraphQLScalarType({
  name: 'DateTime',
  description: 'ISO 8601 date-time string',
  serialize: (value: unknown) => (value instanceof Date ? value.toISOString() : value),
  parseValue: (value: unknown) => new Date(value as string),
})

export const builder = new SchemaBuilder<{
  Context: GraphQLContext
  DefaultFieldNullability: false
  Scalars: {
    DateTime: { Input: Date; Output: Date }
    UserId: { Input: UserId; Output: UserId }
    WineId: { Input: WineId; Output: WineId }
    WineName: { Input: WineName; Output: WineName }
    WineDomain: { Input: WineDomain; Output: WineDomain }
    Appellation: { Input: Appellation; Output: Appellation }
    Classification: { Input: Classification; Output: Classification }
    Country: { Input: Country; Output: Country }
    Region: { Input: Region; Output: Region }
    PersonName: { Input: PersonName; Output: PersonName }
    PlaceName: { Input: PlaceName; Output: PlaceName }
    Year: { Input: Year; Output: Year }
    Eur: { Input: Eur; Output: Eur }
    Latitude: { Input: Latitude; Output: Latitude }
    Longitude: { Input: Longitude; Output: Longitude }
    Rating: { Input: Rating; Output: Rating }
  }
}>({
  defaultFieldNullability: false,
})

builder.addScalarType('DateTime', DateTimeScalar)
builder.queryType({})
builder.mutationType({})
