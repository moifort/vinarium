import SchemaBuilder from '@pothos/core'
import { GraphQLScalarType } from 'graphql'
import type { H3Event } from 'h3'
import type {
  Appellation,
  BeverageId,
  BeverageName,
  Celsius,
  Classification,
  GrapeVariety,
  Notes,
  Producer,
} from '~/domain/beverage/types'
import type { HouseholdId } from '~/domain/household/types'
import type {
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
} from '~/domain/shared/types'
import type { Rating } from '~/domain/tasting/types'
import type { BeverageSatelliteLoaders } from './loaders'

export type GraphQLContext = {
  event: H3Event
  userId: UserId
  loaders: BeverageSatelliteLoaders
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
    HouseholdId: { Input: HouseholdId; Output: HouseholdId }
    BeverageId: { Input: BeverageId; Output: BeverageId }
    BeverageName: { Input: BeverageName; Output: BeverageName }
    Producer: { Input: Producer; Output: Producer }
    Notes: { Input: Notes; Output: Notes }
    Appellation: { Input: Appellation; Output: Appellation }
    Classification: { Input: Classification; Output: Classification }
    GrapeVariety: { Input: GrapeVariety; Output: GrapeVariety }
    Celsius: { Input: Celsius; Output: Celsius }
    Country: { Input: Country; Output: Country }
    Region: { Input: Region; Output: Region }
    PersonName: { Input: PersonName; Output: PersonName }
    PlaceName: { Input: PlaceName; Output: PlaceName }
    Year: { Input: Year; Output: Year }
    Eur: { Input: Eur; Output: Eur }
    Percentage: { Input: Percentage; Output: Percentage }
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
