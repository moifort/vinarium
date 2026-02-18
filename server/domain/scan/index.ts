import type { ScanResult } from '~/domain/scan/types'
import { config } from '~/system/config/index'

const ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'

export namespace Scan {
  export const scanLabel = async (imageBuffer: Buffer) => {
    const { anthropicApiKey } = config()
    const base64 = imageBuffer.toString('base64')

    const response = await $fetch<{
      content: { type: string; id?: string; name?: string; input?: ScanResult }[]
      stop_reason: string
    }>(ANTHROPIC_API_URL, {
      method: 'POST',
      headers: {
        'x-api-key': anthropicApiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: {
        model: 'claude-sonnet-4-5-20250929',
        max_tokens: 1024,
        tools: [
          {
            name: 'extract_wine_info',
            description:
              'Extract structured wine information from a wine label image. Estimate drinkFrom/drinkUntil and market price based on wine type, vintage, appellation, and classification.',
            input_schema: {
              type: 'object',
              properties: {
                name: { type: 'string', description: 'Wine name as shown on label' },
                domain: {
                  type: ['string', 'null'],
                  description: 'Wine domain/producer/château',
                },
                vintage: { type: ['integer', 'null'], description: 'Vintage year' },
                appellation: {
                  type: ['string', 'null'],
                  description: 'Wine appellation (e.g. Bordeaux, Bourgogne)',
                },
                region: { type: ['string', 'null'], description: 'Wine region' },
                country: { type: ['string', 'null'], description: 'Country of origin' },
                color: {
                  type: 'string',
                  enum: ['red', 'white', 'rosé', 'sparkling', 'sweet'],
                  description: 'Wine color/type',
                },
                grapeVarieties: {
                  type: 'array',
                  items: { type: 'string' },
                  description: 'Grape varieties if mentioned',
                },
                classification: {
                  type: ['string', 'null'],
                  description: 'Classification (e.g. Grand Cru, Premier Cru, AOC, AOP, IGP)',
                },
                drinkFrom: {
                  type: ['integer', 'null'],
                  description: 'Estimated year from which the wine can be enjoyed',
                },
                drinkUntil: {
                  type: ['integer', 'null'],
                  description: 'Estimated year until which the wine should be consumed',
                },
                estimatedPrice: {
                  type: ['number', 'null'],
                  description:
                    'Estimated market price in euros based on wine characteristics, vintage, appellation, classification, and producer reputation',
                },
              },
              required: ['name', 'color'],
            },
          },
        ],
        tool_choice: { type: 'tool', name: 'extract_wine_info' },
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'image',
                source: { type: 'base64', media_type: 'image/jpeg', data: base64 },
              },
              {
                type: 'text',
                text: "Analyze this wine label image and extract all visible information. For drinkFrom/drinkUntil, estimate based on the wine's type, vintage, region, and classification. For estimatedPrice, estimate the current market price in euros based on the producer, appellation, classification, and vintage. Use the extract_wine_info tool to return structured data.",
              },
            ],
          },
        ],
      },
    })

    const toolUse = response.content.find((block) => block.type === 'tool_use')
    if (!toolUse?.input) {
      throw new Error('Claude did not return structured wine data')
    }

    return toolUse.input
  }

  const GEMINI_API_URL =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent'

  export const enrichWithSearch = async (scanResult: ScanResult) => {
    const { googleApiKey } = config()

    const wineDescription = [
      scanResult.name,
      scanResult.domain,
      scanResult.vintage ? `millésime ${scanResult.vintage}` : null,
      scanResult.appellation,
      scanResult.region,
      scanResult.country,
    ]
      .filter(Boolean)
      .join(', ')

    const prompt = `Recherche des informations sur ce vin : ${wineDescription}.

Donne-moi les informations suivantes au format JSON strict (sans markdown, juste le JSON) :
{
  "estimatedPrice": number ou null (prix moyen actuel en euros),
  "drinkFrom": number ou null (année à partir de laquelle boire),
  "drinkUntil": number ou null (année limite pour le boire),
  "grapeVarieties": string[] (cépages principaux),
  "region": string ou null (région viticole),
  "country": string ou null (pays),
  "classification": string ou null (classification officielle),
  "appellation": string ou null (appellation)
}

Utilise les données les plus récentes disponibles sur le web. Si tu ne trouves pas une information, mets null.`

    const response = await $fetch<{
      candidates: { content: { parts: { text?: string }[] } }[]
    }>(`${GEMINI_API_URL}?key=${googleApiKey}`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: {
        contents: [{ parts: [{ text: prompt }] }],
        tools: [{ google_search: {} }],
      },
    })

    const text = response.candidates?.[0]?.content?.parts?.find((p) => p.text)?.text
    if (!text) return scanResult

    try {
      const jsonMatch = text.match(/\{[\s\S]*\}/)
      if (!jsonMatch) return scanResult
      const enriched = JSON.parse(jsonMatch[0])

      return {
        ...scanResult,
        estimatedPrice: enriched.estimatedPrice ?? scanResult.estimatedPrice,
        drinkFrom: enriched.drinkFrom ?? scanResult.drinkFrom,
        drinkUntil: enriched.drinkUntil ?? scanResult.drinkUntil,
        grapeVarieties:
          enriched.grapeVarieties?.length > 0 ? enriched.grapeVarieties : scanResult.grapeVarieties,
        region: enriched.region ?? scanResult.region,
        country: enriched.country ?? scanResult.country,
        classification: enriched.classification ?? scanResult.classification,
        appellation: enriched.appellation ?? scanResult.appellation,
      }
    } catch {
      return scanResult
    }
  }
}
