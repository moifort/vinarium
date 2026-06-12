import { GraphQLError } from 'graphql'
import { builder } from '~/domain/shared/graphql/builder'
import { Scan } from '~/system/scan'
import { ScanResultType } from './types'

/** Maximum decoded image size accepted (10 MB). Base64 adds ~33 % overhead,
 *  so the corresponding base64 string limit is ~14 MB of characters. */
const MAX_IMAGE_SIZE_BYTES = 10 * 1024 * 1024
const MAX_BASE64_LENGTH = Math.ceil((MAX_IMAGE_SIZE_BYTES * 4) / 3)

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
      if (imageBase64.length > MAX_BASE64_LENGTH) {
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
