import type { ImportResult } from '~/domain/portability/types'
import { builder } from '~/domain/shared/graphql/builder'

export const ImportResultType = builder.objectRef<ImportResult>('ImportResult').implement({
  description: 'Number of records imported per domain',
  fields: (t) => ({
    wines: t.exposeInt('wines'),
    cellar: t.exposeInt('cellar'),
    tasting: t.exposeInt('tasting'),
    recommendation: t.exposeInt('recommendation'),
    gift: t.exposeInt('gift'),
    journal: t.exposeInt('journal'),
  }),
})
