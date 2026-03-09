import type { Wine } from '~/domain/wine/types'
import * as repository from '~/system/bottle-image/repository'
import { config } from '~/system/config/index'
import { createLogger } from '~/system/logger'

const logger = createLogger('bottle-image')

const GEMINI_API_URL =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp-image-generation:generateContent'

export namespace BottleImage {
  export const generateForWine = async (wine: Wine) => {
    const { googleApiKey, transparentUrl } = config()
    if (!transparentUrl) {
      logger.warn('transparentUrl not configured, skipping bottle image generation')
      return
    }

    if (await repository.exists(wine.id)) return

    logger.info(`Generating bottle image for wine ${wine.id} (${wine.name})`)

    const prompt = buildPrompt(wine)
    const imageBase64 = await generateImage(prompt, googleApiKey)
    const transparentBase64 = await removeBackground(imageBase64, transparentUrl)
    await repository.save(wine.id, transparentBase64)

    logger.success(`Bottle image saved for wine ${wine.id}`)
  }

  const buildPrompt = (wine: Wine) => {
    const glassType = {
      red: 'dark green glass for red wine',
      white: 'clear glass for white wine',
      rosé: 'pink tint glass for rosé wine',
      sparkling: 'champagne-shaped bottle',
      sweet: 'amber glass for sweet wine',
    }[wine.color]

    const labelParts = [`"${wine.name}"`, wine.vintage, wine.domain, wine.appellation]
      .filter(Boolean)
      .join(' ')

    const region = wine.region ?? 'French'

    return `Generate a photorealistic image of a single wine bottle on a solid bright green background (#00FF00).
The bottle should be:
- A ${wine.color} wine bottle (${glassType})
- Centered, elegant, slight angle, professional product photography
- With a realistic label showing: ${labelParts}
- Label style matching ${region} wine tradition
- Soft studio lighting, NO shadows on background, NO reflections, NO other objects
- Background MUST be uniform solid bright green (#00FF00)`
  }

  const generateImage = async (prompt: string, googleApiKey: string) => {
    const response = await $fetch<{
      candidates: {
        content: { parts: { text?: string; inlineData?: { mimeType: string; data: string } }[] }
      }[]
    }>(`${GEMINI_API_URL}?key=${googleApiKey}`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: {
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { responseModalities: ['TEXT', 'IMAGE'] },
      },
    })

    const imagePart = response.candidates?.[0]?.content?.parts?.find((p) => p.inlineData)
    if (!imagePart?.inlineData) {
      throw new Error('Gemini did not return an image')
    }

    return imagePart.inlineData.data
  }

  const removeBackground = async (imageBase64: string, transparentUrl: string) => {
    const imageBuffer = Buffer.from(imageBase64, 'base64')
    const formData = new FormData()
    formData.append('image', new Blob([imageBuffer], { type: 'image/png' }), 'bottle.png')

    const response = await fetch(`${transparentUrl}/remove-background`, {
      method: 'POST',
      body: formData,
      signal: AbortSignal.timeout(120_000),
    })

    if (!response.ok) {
      throw new Error(`Transparent service returned ${response.status}`)
    }

    const resultBuffer = Buffer.from(await response.arrayBuffer())
    return resultBuffer.toString('base64')
  }
}
