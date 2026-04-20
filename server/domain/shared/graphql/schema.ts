import { builder } from './builder'

// Custom scalars must be registered before any type that references them.
import './scalars'

// Domain GraphQL layers are imported here as they come online. Each domain
// owns enums.ts, types.ts, inputs.ts, queries.ts, mutations.ts under its
// infrastructure/graphql/ directory, mirroring the bazar layout.

// Wine domain
import '~/domain/wine/infrastructure/graphql/enums'
import '~/domain/wine/infrastructure/graphql/types'
import '~/domain/wine/infrastructure/graphql/inputs'
import '~/domain/wine/infrastructure/graphql/queries'
import '~/domain/wine/infrastructure/graphql/mutations'

export const schema = builder.toSchema()
