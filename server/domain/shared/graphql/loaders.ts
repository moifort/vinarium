// DataLoaders are populated as domains are added to the GraphQL schema.
// Each domain's `infrastructure/graphql/types.ts` may register additional
// loaders here when nested fields would trigger N+1 reads.
export const createLoaders = () => ({})

export type Loaders = ReturnType<typeof createLoaders>
