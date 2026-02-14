import type { ScanResult } from '~/ai/types'
import { config } from '~/config/index'
import type { Wine } from '~/wine/types'

const ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'

export namespace AI {
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
                alcoholContent: { type: ['number', 'null'], description: 'Alcohol percentage' },
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

  export const getAdvice = async (wines: Wine[], occasion?: string) => {
    const { anthropicApiKey } = config()

    const winesSummary = wines
      .map(
        (w) =>
          `- ${w.name}${w.vintage ? ` ${w.vintage}` : ''} (${w.color})${w.appellation ? `, ${w.appellation}` : ''}${w.drinkFrom || w.drinkUntil ? ` [boire ${w.drinkFrom ?? '?'}-${w.drinkUntil ?? '?'}]` : ''}`,
      )
      .join('\n')

    const prompt = occasion
      ? `Voici ma cave à vin :\n${winesSummary}\n\nOccasion : ${occasion}\n\nRecommande-moi des bouteilles à ouvrir pour cette occasion, en expliquant pourquoi.`
      : `Voici ma cave à vin :\n${winesSummary}\n\nDonne-moi des conseils sur ma cave : quelles bouteilles ouvrir bientôt, lesquelles garder, et des suggestions pour équilibrer ma collection.`

    const response = await $fetch<{
      content: { type: string; text?: string }[]
    }>(ANTHROPIC_API_URL, {
      method: 'POST',
      headers: {
        'x-api-key': anthropicApiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: {
        model: 'claude-sonnet-4-5-20250929',
        max_tokens: 2048,
        messages: [{ role: 'user', content: prompt }],
        system:
          "Tu es un sommelier expert. Réponds en français. Sois précis et pratique dans tes conseils. Utilise l'année actuelle pour évaluer la maturité des vins.",
      },
    })

    const textBlock = response.content.find((block) => block.type === 'text')
    return textBlock?.text ?? 'Aucun conseil disponible.'
  }
}
