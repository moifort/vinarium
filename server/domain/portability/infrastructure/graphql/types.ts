import type { ImportResult } from '~/domain/portability/types'
import { builder } from '~/domain/shared/graphql/builder'

export const ImportResultType = builder.objectRef<ImportResult>('ImportResult').implement({
  description:
    'Per-domain tally returned after restoring an export envelope.\n\n' +
    'Each field counts the records written for one domain during `importData`. The import ' +
    'replaces the existing records, so these counts reflect the final state of the account after ' +
    'the round-trip, not additions on top of prior data.',
  fields: (t) => ({
    wines: t.exposeInt('wines', { description: 'Number of beverages (wines) imported' }),
    cellar: t.exposeInt('cellar', { description: 'Number of cellar bottle placements imported' }),
    tasting: t.exposeInt('tasting', { description: 'Number of tasting notes imported' }),
    recommendation: t.exposeInt('recommendation', {
      description: 'Number of recommendations imported',
    }),
    gift: t.exposeInt('gift', { description: 'Number of gift records imported' }),
    journal: t.exposeInt('journal', { description: 'Number of journal entries imported' }),
  }),
})
