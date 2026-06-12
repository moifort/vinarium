import { GraphQLError } from 'graphql'
import { builder } from '~/domain/shared/graphql/builder'
import { Scan } from '~/system/scan'
import { imageWithinSizeLimit } from '~/system/scan/limits'
import { ScanResultType } from './types'

builder.mutationField('scanWine', (t) =>
  t.field({
    type: ScanResultType,
    description:
      'Analyze a wine label image (base64-encoded JPEG) and return structured fields. The result is cached server-side by SHA-256, so the same label scanned twice avoids re-calling Claude / Gemini.',
    args: {
      imageBase64: t.arg.string({
        required: true,
        description: 'JPEG image, base64-encoded (no data URL prefix)',
      }),
    },
    resolve: async (_root, { imageBase64 }) => {
      if (!imageWithinSizeLimit(imageBase64.length)) {
        throw new GraphQLError('Image exceeds the 10 MB size limit', {
          extensions: { code: 'IMAGE_TOO_LARGE' },
        })
      }
      try {
        const buffer = Buffer.from(imageBase64, 'base64')
        return await Scan.scanWithCache(buffer)
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Scan failed'
        throw new GraphQLError(message, { extensions: { code: 'SCAN_FAILED' } })
      }
    },
  }),
)
