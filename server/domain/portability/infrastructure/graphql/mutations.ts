import { GraphQLError } from 'graphql'
import { PortabilityUseCase } from '~/domain/portability/use-case'
import { builder } from '~/domain/shared/graphql/builder'
import { ImportResultType } from './types'

builder.mutationField('importData', (t) =>
  t.field({
    type: ImportResultType,
    description:
      'Restore a full account from an export envelope, replacing existing records.\n\n' +
      'Consumes the JSON string produced by `exportData` and rewrites every domain from it, so ' +
      'the operation is destructive: prior records are replaced, not merged. The envelope ' +
      "`schemaVersion` must match the server's supported version. Returns the per-domain counts " +
      'written.',
    args: {
      payload: t.arg.string({
        required: true,
        description: 'JSON export envelope (from `exportData`) to restore for the current user',
      }),
    },
    resolve: async (_root, { payload }, { userId }) => {
      const result = await PortabilityUseCase.importAll(userId, payload)
      if ('error' in result) throw new GraphQLError(result.error)
      return result
    },
  }),
)
