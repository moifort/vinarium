import { createHash } from 'node:crypto'
import { config } from '~/system/config/index'
import { createLogger } from '~/system/logger'
import {
  EnrichSchema,
  ImageHash,
  parseScanResponse,
  ScanResultSchema,
} from '~/system/scan/primitives'
import * as repository from '~/system/scan/repository'
import type { ImageHash as ImageHashType, ScanResult } from '~/system/scan/types'

const log = createLogger('scan')

const GEMINI_API_URL =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent'

export namespace Scan {
  export const scanWithCache = async (imageBuffer: Buffer) => {
    const imageHash = hashImage(imageBuffer)
    const cached = await repository.findBy(imageHash)
    // Re-parse cached results: entries written before multi-beverage support
    // have no beverageType and get the wine default.
    if (cached) return ScanResultSchema.parse(cached.result)
    const scanResult = await scanLabel(imageBuffer)
    const enriched = await enrichWithSearch(scanResult)
    repository
      .save({ imageHash, result: enriched, cachedAt: new Date() })
      .catch((err) => log.warn('Failed to write scan result to cache', err))
    return enriched
  }

  const scanLabel = async (imageBuffer: Buffer): Promise<ScanResult> => {
    const { googleApiKey } = config()
    const base64 = imageBuffer.toString('base64')

    const response = await $fetch<{
      candidates: { content: { parts: { text?: string }[] } }[]
    }>(`${GEMINI_API_URL}?key=${googleApiKey}`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: {
        contents: [
          {
            parts: [
              { inline_data: { mime_type: 'image/jpeg', data: base64 } },
              {
                text: "Analyse cette image d'étiquette de boisson alcoolisée et extrais toutes les informations visibles.\n\nÉTAPE 1 — Détermine d'abord beverageType parmi : wine (vin), spirit (spiritueux/alcool fort distillé), beer (bière), sake (saké japonais), cider (cidre/poiré), other. Indices de classification :\n- wine : mention de cépages, d'appellation (AOC/AOP/DOC), millésime, ~11-15% vol, bouteille bordelaise/bourguignonne.\n- spirit : whisky, rhum, gin, vodka, cognac, armagnac, tequila, mezcal, liqueur — souvent 37,5-50%+ vol, mention d'âge (ex : 12 ans) ou de distillerie.\n- beer : brasserie, IPA/Lager/Stout/Pils/Triple, ~4-9% vol, canette ou bouteille capsulée.\n- sake : texte japonais, mention 純米/吟醸/大吟醸 (Junmai/Ginjo/Daiginjo), kura (brasserie de saké), ~14-17% vol.\n- cider : pomme/poire, cidrerie, Brut/Doux/Fermier, ~2-8% vol.\nSi le type est réellement indéterminable, mets 'other'.\n\nÉTAPE 2 — Selon le type :\n- Pour un vin : color est OBLIGATOIRE, et estime drinkFrom/drinkUntil selon le type de vin, le millésime, la région et la classification.\n- Pour toute autre boisson : mets color à null, laisse les champs spécifiques au vin (grapeVarieties, appellation, classification, drinkFrom, drinkUntil) à null, et renseigne style avec un exemple adapté au type : spirit → Single Malt, Blended, Bourbon, Rhum agricole, London Dry… ; beer → IPA, Stout, Pils, Lager, Triple… ; sake → Junmai, Ginjo, Daiginjo, Honjozo… ; cider → Brut, Doux, Fermier, Poiré…\n\nLe champ domain désigne le producteur : domaine, distillerie, brasserie ou kura. Pour alcoholContent, indique le degré d'alcool en % vol s'il est visible. Pour estimatedPrice, estime le prix actuel du marché en euros selon le producteur et les caractéristiques. Toutes les valeurs textuelles (nom, producteur, région, pays, cépages, appellation, classification, style) doivent être en français. Si une information n'est pas visible ou estimable, mets la valeur à null (ou un tableau vide pour grapeVarieties).",
              },
            ],
          },
        ],
        generationConfig: {
          responseMimeType: 'application/json',
          responseSchema: {
            type: 'object',
            properties: {
              name: {
                type: 'string',
                description: "Nom de la boisson tel qu'indiqué sur l'étiquette",
              },
              beverageType: {
                type: 'string',
                enum: ['wine', 'spirit', 'beer', 'sake', 'cider', 'other'],
                description: "Type de boisson ; 'other' si indéterminable",
              },
              style: {
                type: 'string',
                nullable: true,
                description: 'Style de la boisson hors vin (ex : IPA, Single Malt, Junmai)',
              },
              alcoholContent: {
                type: 'number',
                nullable: true,
                description: "Degré d'alcool en % vol",
              },
              domain: {
                type: 'string',
                nullable: true,
                description: 'Producteur : domaine, distillerie, brasserie ou kura',
              },
              vintage: { type: 'integer', nullable: true, description: 'Année du millésime' },
              appellation: {
                type: 'string',
                nullable: true,
                description: 'Appellation (ex : Bordeaux, Bourgogne)',
              },
              region: {
                type: 'string',
                nullable: true,
                description: 'Région viticole (en français)',
              },
              country: {
                type: 'string',
                nullable: true,
                description: "Pays d'origine (en français, ex : France, Espagne, Italie)",
              },
              color: {
                type: 'string',
                enum: ['red', 'white', 'rosé', 'sparkling', 'sweet'],
                nullable: true,
                description: 'Couleur/type du vin — obligatoire pour un vin, null sinon',
              },
              grapeVarieties: {
                type: 'array',
                items: { type: 'string' },
                description: 'Cépages mentionnés (en français)',
              },
              classification: {
                type: 'string',
                nullable: true,
                description: 'Classification (ex : Grand Cru, Premier Cru, AOC, AOP, IGP)',
              },
              drinkFrom: {
                type: 'integer',
                nullable: true,
                description: 'Année estimée à partir de laquelle le vin peut être apprécié',
              },
              drinkUntil: {
                type: 'integer',
                nullable: true,
                description: "Année estimée jusqu'à laquelle le vin devrait être consommé",
              },
              estimatedPrice: {
                type: 'number',
                nullable: true,
                description:
                  "Prix estimé en euros basé sur les caractéristiques, le millésime, l'appellation, la classification et la réputation du producteur",
              },
            },
            required: ['name', 'beverageType'],
            propertyOrdering: [
              'name',
              'beverageType',
              'style',
              'alcoholContent',
              'domain',
              'vintage',
              'appellation',
              'region',
              'country',
              'color',
              'grapeVarieties',
              'classification',
              'drinkFrom',
              'drinkUntil',
              'estimatedPrice',
            ],
          },
        },
      },
    })

    const text = response.candidates?.[0]?.content?.parts?.find((p) => p.text)?.text
    if (!text) throw new Error('Gemini did not return structured wine data')

    return parseScanResponse(text)
  }

  const BEVERAGE_LABELS: Record<ScanResult['beverageType'], string> = {
    wine: 'vin',
    spirit: 'spiritueux',
    beer: 'bière',
    sake: 'saké',
    cider: 'cidre',
    other: 'boisson',
  }

  const enrichWithSearch = async (scanResult: ScanResult) => {
    const { googleApiKey } = config()

    const description = [
      scanResult.name,
      scanResult.domain,
      scanResult.style,
      scanResult.vintage ? `millésime ${scanResult.vintage}` : null,
      scanResult.appellation,
      scanResult.region,
      scanResult.country,
    ]
      .filter(Boolean)
      .join(', ')

    const wineFields = `  "drinkFrom": number ou null (année à partir de laquelle boire),
  "drinkUntil": number ou null (année limite pour le boire),
  "grapeVarieties": string[] (cépages principaux),
  "classification": string ou null (classification officielle),
  "appellation": string ou null (appellation),`

    const STYLE_EXAMPLES: Record<ScanResult['beverageType'], string> = {
      wine: '',
      spirit: 'Single Malt, Blended, Bourbon, Rhum agricole, London Dry',
      beer: 'IPA, Stout, Pils, Lager, Triple',
      sake: 'Junmai, Ginjo, Daiginjo, Honjozo',
      cider: 'Brut, Doux, Fermier, Poiré',
      other: 'style de la boisson',
    }

    const otherFields = `  "style": string ou null (style, ex : ${STYLE_EXAMPLES[scanResult.beverageType]}),`

    const prompt = `Recherche des informations sur ce ${BEVERAGE_LABELS[scanResult.beverageType]} : ${description}.

Donne-moi les informations suivantes au format JSON strict (sans markdown, juste le JSON) :
{
  "estimatedPrice": number ou null (prix moyen actuel en euros),
  "alcoholContent": number ou null (degré d'alcool en % vol),
${scanResult.beverageType === 'wine' ? wineFields : otherFields}
  "region": string ou null (région de production),
  "country": string ou null (pays)
}

Toutes les valeurs textuelles doivent être en français (noms de pays, régions, cépages, etc.).
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
      const enriched = EnrichSchema.parse(JSON.parse(jsonMatch[0]))

      return {
        ...scanResult,
        estimatedPrice: enriched.estimatedPrice ?? scanResult.estimatedPrice,
        alcoholContent: enriched.alcoholContent ?? scanResult.alcoholContent,
        style: enriched.style ?? scanResult.style,
        drinkFrom: enriched.drinkFrom ?? scanResult.drinkFrom,
        drinkUntil: enriched.drinkUntil ?? scanResult.drinkUntil,
        grapeVarieties:
          enriched.grapeVarieties && enriched.grapeVarieties.length > 0
            ? enriched.grapeVarieties
            : scanResult.grapeVarieties,
        region: enriched.region ?? scanResult.region,
        country: enriched.country ?? scanResult.country,
        classification: enriched.classification ?? scanResult.classification,
        appellation: enriched.appellation ?? scanResult.appellation,
      }
    } catch {
      return scanResult
    }
  }

  const hashImage = (imageBuffer: Buffer): ImageHashType =>
    ImageHash(createHash('sha256').update(imageBuffer).digest('hex'))
}
