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

// Cellar domain (extends WineType with .cellar field)
import '~/domain/cellar/infrastructure/graphql/types'
import '~/domain/cellar/infrastructure/graphql/inputs'
import '~/domain/cellar/infrastructure/graphql/queries'
import '~/domain/cellar/infrastructure/graphql/mutations'

// Journal domain (extends WineType with .history field)
import '~/domain/journal/infrastructure/graphql/types'
import '~/domain/journal/infrastructure/graphql/queries'

// Tasting domain (extends WineType with .consumption field)
import '~/domain/tasting/infrastructure/graphql/types'
import '~/domain/tasting/infrastructure/graphql/inputs'
import '~/domain/tasting/infrastructure/graphql/mutations'

// Gift domain (extends WineType with .gift field)
import '~/domain/gift/infrastructure/graphql/types'

// Recommendation domain (extends WineType with .recommendation field)
import '~/domain/recommendation/infrastructure/graphql/types'
import '~/domain/recommendation/infrastructure/graphql/inputs'
import '~/domain/recommendation/infrastructure/graphql/mutations'

export const schema = builder.toSchema()
