import { make } from 'ts-brand'
import { z } from 'zod'
import { retainedSubtype } from '~/domain/beverage/business-rules'
import { pureColor, subtypeFromLegacy } from '~/domain/beverage/legacy-mapping'
import { BEVERAGE_SUBTYPE_VALUES } from '~/domain/beverage/primitives'
import type { ImageHash as ImageHashType, ScanResult } from '~/domain/scan/types'

export const ImageHash = (value: unknown) => {
  const v = z
    .string()
    .regex(/^[0-9a-f]{64}$/)
    .parse(value)
  return make<ImageHashType>()(v)
}

const nullToUndefined = <T>(schema: z.ZodNullable<z.ZodType<T>>) =>
  schema.transform((v) => v ?? undefined)

// A hallucinated out-of-enum subtype must degrade to "no subtype", never fail
// the whole parse (the rest of the scan is still valuable).
const lenientSubtype = z
  .enum(BEVERAGE_SUBTYPE_VALUES)
  .nullish()
  .catch(undefined)
  .transform((v) => v ?? undefined)

// Gemini's structured output marks absent fields as explicit null (the prompt
// instructs it to), so every optional field must accept null and coerce it away.
// The input side still accepts the legacy cache shape (5-value color enum,
// free-text style) and normalizes it to the current model in the transform.
export const ScanResultSchema = z
  .object({
    // Legacy cache entries predate this field; absent means the scan succeeded,
    // so they default to recognized.
    recognized: z.boolean().default(true),
    name: z.string(),
    // Absent on results cached before multi-beverage support: those are all wines.
    beverageType: z.enum(['wine', 'spirit', 'beer', 'sake', 'cider', 'other']).default('wine'),
    color: nullToUndefined(
      z.enum(['red', 'white', 'rosé', 'sparkling', 'sweet']).nullable(),
    ).optional(),
    subtype: lenientSubtype.optional(),
    style: nullToUndefined(z.string().nullable()).optional(),
    alcoholContent: nullToUndefined(z.number().nullable()).optional(),
    domain: nullToUndefined(z.string().nullable()).optional(),
    vintage: nullToUndefined(z.number().int().nullable()).optional(),
    appellation: nullToUndefined(z.string().nullable()).optional(),
    region: nullToUndefined(z.string().nullable()).optional(),
    country: nullToUndefined(z.string().nullable()).optional(),
    grapeVarieties: nullToUndefined(z.array(z.string()).nullable()).optional(),
    classification: nullToUndefined(z.string().nullable()).optional(),
    drinkFrom: nullToUndefined(z.number().int().nullable()).optional(),
    drinkUntil: nullToUndefined(z.number().int().nullable()).optional(),
    estimatedPrice: nullToUndefined(z.number().nullable()).optional(),
  })
  .transform(({ style, ...raw }) => ({
    ...raw,
    color: pureColor(raw.color),
    // retainedSubtype also guards against a model answer incoherent with the
    // beverage type (a 'junmai' beer) — better no subtype than a nonsensical one.
    subtype: retainedSubtype(
      raw.beverageType,
      raw.subtype ?? subtypeFromLegacy({ style, color: raw.color }),
    ),
  }))

export const EnrichSchema = z.object({
  subtype: lenientSubtype.optional(),
  alcoholContent: nullToUndefined(z.number().nullable()).optional(),
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
