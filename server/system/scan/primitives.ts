import { make } from 'ts-brand'
import { z } from 'zod'
import type { ImageHash as ImageHashType, ScanResult } from '~/system/scan/types'

export const ImageHash = (value: unknown) => {
  const v = z
    .string()
    .regex(/^[0-9a-f]{64}$/)
    .parse(value)
  return make<ImageHashType>()(v)
}

const nullToUndefined = <T>(schema: z.ZodNullable<z.ZodType<T>>) =>
  schema.transform((v) => v ?? undefined)

export const ScanResultSchema: z.ZodType<ScanResult> = z.object({
  name: z.string(),
  color: z.enum(['red', 'white', 'rosé', 'sparkling', 'sweet']),
  domain: z.string().optional(),
  vintage: z.number().int().optional(),
  appellation: z.string().optional(),
  region: z.string().optional(),
  country: z.string().optional(),
  grapeVarieties: z.array(z.string()).optional(),
  classification: z.string().optional(),
  drinkFrom: z.number().int().optional(),
  drinkUntil: z.number().int().optional(),
  estimatedPrice: z.number().optional(),
})

export const EnrichSchema = z.object({
  estimatedPrice: nullToUndefined(z.number().nullable()).optional(),
  drinkFrom: nullToUndefined(z.number().int().nullable()).optional(),
  drinkUntil: nullToUndefined(z.number().int().nullable()).optional(),
  grapeVarieties: z.array(z.string()).optional(),
  region: nullToUndefined(z.string().nullable()).optional(),
  country: nullToUndefined(z.string().nullable()).optional(),
  classification: nullToUndefined(z.string().nullable()).optional(),
  appellation: nullToUndefined(z.string().nullable()).optional(),
})

export const parseScanResponse = (text: string): ScanResult => {
  const parsed = JSON.parse(text)
  return ScanResultSchema.parse(parsed)
}
