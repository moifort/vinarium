import { PortabilityUseCase } from '~/domain/portability/use-case'
import { builder } from '~/domain/shared/graphql/builder'

builder.queryField('exportData', (t) =>
  t.string({
    description:
      'GDPR-style full export of the current user account as a JSON string.\n\n' +
      'Serializes every record the user owns (wines, cellar placements, tastings, ' +
      'recommendations, gifts, journal) into one envelope stamped with a `schemaVersion`. The ' +
      'string is the exact payload `importData` consumes, enabling a lossless export/import ' +
      'round-trip.',
    resolve: async (_root, _args, { userId }) => {
      const envelope = await PortabilityUseCase.exportAll(userId)
      return JSON.stringify(envelope)
    },
  }),
)
