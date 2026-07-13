import { Scan } from '~/domain/scan'
import { imageWithinSizeLimit } from '~/domain/scan/limits'
import { builder } from '~/domain/shared/graphql/builder'
import { domainError } from '~/domain/shared/graphql/errors'
import { ScanResultType } from './types'

builder.mutationField('scanBeverage', (t) =>
  t.field({
    type: ScanResultType,
    description:
      'Analyze a beverage label image (base64-encoded JPEG) and return structured fields. The result is cached server-side by SHA-256, so the same label scanned twice avoids re-calling Claude / Gemini.',
    args: {
      imageBase64: t.arg.string({
        required: true,
        description: 'JPEG image, base64-encoded (no data URL prefix)',
      }),
    },
    resolve: async (_root, { imageBase64 }) => {
      if (!imageWithinSizeLimit(imageBase64.length))
        return domainError('IMAGE_TOO_LARGE', 'Image exceeds the 10 MB size limit')
      try {
        const buffer = Buffer.from(imageBase64, 'base64')
        return await Scan.scanWithCache(buffer)
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Scan failed'
        return domainError('SCAN_FAILED', message)
      }
    },
  }),
)
