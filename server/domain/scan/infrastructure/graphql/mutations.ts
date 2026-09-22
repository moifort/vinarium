import { AdminCommand } from '~/domain/admin/command'
import { EntitlementQuery } from '~/domain/entitlement/query'
import { exhausted } from '~/domain/quota/business-rules'
import { QuotaCommand } from '~/domain/quota/command'
import { QuotaQuery } from '~/domain/quota/query'
import { Scan } from '~/domain/scan'
import { imageWithinSizeLimit } from '~/domain/scan/limits'
import { scanLanguageFrom } from '~/domain/scan/primitives'
import type { ScanLanguage } from '~/domain/scan/types'
import type { GraphQLContext } from '~/domain/shared/graphql/builder'
import { builder } from '~/domain/shared/graphql/builder'
import { domainError } from '~/domain/shared/graphql/errors'
import { ScanResultType } from './types'

builder.mutationField('scanBeverage', (t) =>
  t.field({
    type: ScanResultType,
    description:
      'Extract structured beverage details from a bottle-label photo using AI.\n\n' +
      'Reads a base64-encoded JPEG with a vision model (Gemini) and, when a beverage is ' +
      'recognized, enriches it with a web search. A `description` typed alongside is read with ' +
      'the label and settles what it does not show. The result is cached server-side by SHA-256 ' +
      'of the image and the description, so scanning the same label twice avoids re-calling the ' +
      'models. Check `recognized` on the result: false means no beverage was identified.\n\n' +
      'Spends one scan of the allowance (see the `quota` query): the month first, then the scans ' +
      'granted at onboarding. Only a real model call is charged, a cached label is free. Fails ' +
      'with `QUOTA_EXHAUSTED` once nothing is left anywhere, `IMAGE_TOO_LARGE` above the 10 MB ' +
      'limit, or `SCAN_FAILED` when the model call errors.',
    args: {
      imageBase64: t.arg.string({
        required: true,
        description: 'Bottle-label JPEG, base64-encoded (no data URL prefix), up to 10 MB',
      }),
      description: t.arg({
        type: 'BottleDescription',
        required: false,
        description: 'What the label does not show, typed by the photographer (optional)',
      }),
    },
    resolve: async (_root, { imageBase64, description }, context) => {
      if (!imageWithinSizeLimit(imageBase64.length))
        return domainError('IMAGE_TOO_LARGE', 'Image exceeds the 10 MB size limit')
      const buffer = Buffer.from(imageBase64, 'base64')
      return meteredScan(context, (language) =>
        Scan.scanWithCache(buffer, language, description ?? undefined),
      )
    },
  }),
)

builder.mutationField('identifyBeverage', (t) =>
  t.field({
    type: ScanResultType,
    description:
      'Identify a beverage from a typed description, without a photo.\n\n' +
      'The description ("Grange des Pères 2016 rouge") is read by the same model as a label ' +
      'and the answer has the same shape as `scanBeverage`, enriched with a web search when a ' +
      'beverage is recognized. Cached server-side regardless of case and spacing. Check ' +
      '`recognized` on the result: false means the text names no identifiable beverage.\n\n' +
      'Spends one scan of the allowance, on the same terms as `scanBeverage`. Fails with ' +
      '`QUOTA_EXHAUSTED` once nothing is left anywhere, or `SCAN_FAILED` when the model call ' +
      'errors.',
    args: {
      description: t.arg({
        type: 'BottleDescription',
        required: true,
        description: 'The beverage as remembered: name, producer, vintage, colour',
      }),
    },
    resolve: (_root, { description }, context) =>
      meteredScan(context, (language) => Scan.identifyWithCache(description, language)),
  }),
)

// The allowance check, the metering and the cost telemetry, the same for a
// photo and a description: both are one scan to the caller.
const meteredScan = async (
  { userId, event }: GraphQLContext,
  run: (language: ScanLanguage) => ReturnType<typeof Scan.scanWithCache>,
) => {
  const [plan, quota, credit] = await Promise.all([
    EntitlementQuery.planOf(userId),
    QuotaQuery.ofCurrentMonth(userId),
    QuotaQuery.creditOf(userId),
  ])
  if (exhausted(plan, quota, credit))
    return domainError('QUOTA_EXHAUSTED', 'Scan allowance is used up')

  // The AI writes its free-text values in the caller's language; the header
  // also partitions the scan cache so languages never cross-contaminate.
  const language = scanLanguageFrom(event && getHeader(event, 'accept-language'))

  try {
    const { result, cacheHit, usage } = await run(language)
    // Metered after the fact, and only on a real model call: a Gemini failure
    // must not cost the caller a scan, and a cache hit costs us nothing.
    if (!cacheHit) await QuotaCommand.record(userId, plan)
    // Cost telemetry for the admin metrics — never on the scan's critical
    // path: a failed metrics write must not fail the scan that produced it.
    await AdminCommand.recordAiUsage({ cacheHit, ...usage }).catch(() => {})
    return result
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Scan failed'
    return domainError('SCAN_FAILED', message)
  }
}
