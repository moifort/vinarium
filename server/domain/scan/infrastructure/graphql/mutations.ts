import { EntitlementQuery } from '~/domain/entitlement/query'
import { exhausted } from '~/domain/quota/business-rules'
import { QuotaCommand } from '~/domain/quota/command'
import { QuotaQuery } from '~/domain/quota/query'
import { Scan } from '~/domain/scan'
import { imageWithinSizeLimit } from '~/domain/scan/limits'
import { builder } from '~/domain/shared/graphql/builder'
import { domainError } from '~/domain/shared/graphql/errors'
import { ScanResultType } from './types'

builder.mutationField('scanBeverage', (t) =>
  t.field({
    type: ScanResultType,
    description:
      'Extract structured beverage details from a bottle-label photo using AI.\n\n' +
      'Reads a base64-encoded JPEG with a vision model (Gemini) and, when a beverage is ' +
      'recognized, enriches it with a web search. The result is cached server-side by SHA-256, so ' +
      'scanning the same label twice avoids re-calling the models. Check `recognized` on the ' +
      'result: false means no beverage was identified.\n\n' +
      'Spends one scan of the monthly allowance (see `me.quota`), and only when the models are ' +
      'really called: a cached label is free. Fails with `QUOTA_EXHAUSTED` once the allowance is ' +
      'used up, `IMAGE_TOO_LARGE` above the 10 MB limit, or `SCAN_FAILED` when the model call ' +
      'errors.',
    args: {
      imageBase64: t.arg.string({
        required: true,
        description: 'Bottle-label JPEG, base64-encoded (no data URL prefix), up to 10 MB',
      }),
    },
    resolve: async (_root, { imageBase64 }, { userId }) => {
      if (!imageWithinSizeLimit(imageBase64.length))
        return domainError('IMAGE_TOO_LARGE', 'Image exceeds the 10 MB size limit')

      const plan = await EntitlementQuery.planOf(userId)
      const quota = await QuotaQuery.ofCurrentMonth(userId)
      if (exhausted(plan, quota))
        return domainError('QUOTA_EXHAUSTED', 'Monthly scan allowance is used up')

      try {
        const buffer = Buffer.from(imageBase64, 'base64')
        const { result, cacheHit } = await Scan.scanWithCache(buffer)
        // Metered after the fact, and only on a real model call: a Gemini failure
        // must not cost the caller a scan, and a cache hit costs us nothing.
        if (!cacheHit) await QuotaCommand.record(userId)
        return result
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Scan failed'
        return domainError('SCAN_FAILED', message)
      }
    },
  }),
)
