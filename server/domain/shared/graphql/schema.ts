import { builder } from './builder'

// Custom scalars must be registered before any type that references them.
import './scalars'

// Domain GraphQL layers are imported here as they come online. Each domain
// owns enums.ts, types.ts, inputs.ts, queries.ts, mutations.ts under its
// infrastructure/graphql/ directory, mirroring the bazar layout.

export const schema = builder.toSchema()
