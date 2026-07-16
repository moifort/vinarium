#!/usr/bin/env bun
/**
 * Generates App Store marketing screenshots ("triptychs") with Nano Banana Pro.
 *
 * Each triptych is ONE continuous 4:3 panorama: Nano Banana Pro renders the
 * scene with three phone mockups whose screens are solid magenta placeholders,
 * then composite-panorama.swift pastes the real app screenshots from
 * screenshots/ onto those screens (pixel-perfect UI, no generative text
 * glitches). The panorama is finally sliced into three 1206x2622 portrait
 * panels (the 6.9" size already accepted by App Store Connect) so the
 * background flows across adjacent App Store screenshots.
 *
 * Usage: bun scripts/generate-appstore-previews.ts [1|2]  (default: both)
 * Requires NITRO_GOOGLE_API_KEY in .env (loaded automatically by bun).
 */
import { mkdir, mkdtemp } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { $ } from 'bun'

const MODEL = 'gemini-3-pro-image'
const PANEL_WIDTH = 1206
const PANEL_HEIGHT = 2622
const TRIPTYCH_WIDTH = PANEL_WIDTH * 3

const repoRoot = join(import.meta.dir, '..')
const screenshotsDir = join(repoRoot, 'screenshots')
const outputDir = join(screenshotsDir, 'appstore')
const compositor = join(import.meta.dir, 'composite-panorama.swift')

type Panel = { source: string; output: string; caption: string }
type Triptych = { id: number; scene: string; panels: [Panel, Panel, Panel] }

const TRIPTYCHS: Triptych[] = [
  {
    id: 1,
    scene:
      'a moody high-end wine cellar: dark oak shelves with softly lit wine bottles receding into ' +
      'depth-of-field, warm amber glow, subtle burgundy-to-plum gradient light',
    panels: [
      { source: 'dashboard.png', output: '01-accueil.png', caption: "Votre cave en un coup d'œil" },
      { source: 'cellar.png', output: '02-cave.png', caption: 'Chaque bouteille à sa place' },
      { source: 'wine-list.png', output: '03-vins.png', caption: 'Toute votre collection' },
    ],
  },
  {
    id: 2,
    scene:
      'an elegant tasting-room scene: dark wood surface, a glass of red wine and a fine bottle in ' +
      'soft bokeh, warm candle-like ambient light, subtle burgundy-to-plum gradient',
    panels: [
      { source: 'scan.png', output: '04-scan.png', caption: "Scannez, l'IA fait le reste" },
      {
        source: 'wine-detail.png',
        output: '05-fiche-vin.png',
        caption: 'Apogée, origine, emplacement',
      },
      { source: 'journal.png', output: '06-journal.png', caption: 'Revivez chaque dégustation' },
    ],
  },
]

const buildPrompt = (triptych: Triptych) => {
  const [left, center, right] = triptych.panels
  return `You are designing App Store marketing screenshots for "Vinarium", a premium French wine-cellar management iOS app.

Create ONE single seamless panoramic marketing image (4:3 landscape). It will be sliced vertically into THREE equal portrait panels (left, center, right) shown side by side on the App Store, so:

- The background is one continuous scene flowing across the whole image with no visible seams: ${triptych.scene}.
- Exactly three iPhone mockups with thin dark titanium frames, perfectly front-facing (zero perspective tilt or rotation), all at the same size and the same vertical position, with a soft premium drop shadow: one centered in the left third, one centered in the middle third, one centered in the right third.
- Each phone's screen is a single flat solid pure magenta (#FF00FF) panel filling the entire display edge to edge, following the display's rounded corners. Perfectly uniform magenta: no gradients, no reflections, no glare, no UI, no notch, no camera island, no text. The real app screenshots will be composited onto these magenta panels afterwards, so anything drawn on them would be destroyed.
- Above each phone, one short French caption on a single line, in an elegant modern sans-serif, white with a subtle golden sheen, large and readable:
  - left: "${left.caption}"
  - center: "${center.caption}"
  - right: "${right.caption}"
- CRITICAL composition rule: the image will be cut along two vertical lines at exactly 1/3 and 2/3 of the width. No phone and no text may touch those lines; keep at least 5% of the total width clear on both sides of each cut line. Only the background crosses the cut lines.
- Palette: deep burgundy (#8C1229), plum, warm gold accents (#D4AE59); dark, sophisticated, high-end wine brand aesthetic. No other text, no logos, no watermarks anywhere.`
}

const apiKey = process.env.NITRO_GOOGLE_API_KEY
if (!apiKey) {
  console.error('NITRO_GOOGLE_API_KEY is not set (expected in .env)')
  process.exit(1)
}

const generatePanorama = async (triptych: Triptych, workDir: string) => {
  // Fail on a missing source screenshot before spending money on the API call.
  for (const panel of triptych.panels) {
    if (!(await Bun.file(join(screenshotsDir, panel.source)).exists())) {
      throw new Error(`Missing source screenshot: ${join(screenshotsDir, panel.source)}`)
    }
  }
  console.log(`Triptych ${triptych.id}: generating panorama with ${MODEL}...`)
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`,
    {
      method: 'POST',
      headers: { 'x-goog-api-key': apiKey, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: buildPrompt(triptych) }] }],
        generationConfig: {
          responseModalities: ['TEXT', 'IMAGE'],
          imageConfig: { aspectRatio: '4:3', imageSize: '4K' },
        },
      }),
    },
  )
  if (!response.ok) {
    throw new Error(`Gemini API error ${response.status}: ${await response.text()}`)
  }
  const result = (await response.json()) as {
    candidates?: { content?: { parts?: { inlineData?: { data: string } }[] } }[]
  }
  const image = result.candidates?.[0]?.content?.parts?.find((part) => part.inlineData)?.inlineData
  if (!image) {
    throw new Error(`No image in response: ${JSON.stringify(result).slice(0, 2000)}`)
  }
  const panoramaPath = join(workDir, `panorama-${triptych.id}.png`)
  await Bun.write(panoramaPath, Buffer.from(image.data, 'base64'))
  console.log(`Triptych ${triptych.id}: panorama saved to ${panoramaPath}`)
  return panoramaPath
}

// Normalize the panorama to exactly 3618x2622 so screenshots are composited at
// final resolution (a single downscale) before the panorama is cut into columns.
const normalizePanorama = async (panoramaPath: string) => {
  await $`sips --resampleWidth ${TRIPTYCH_WIDTH} ${panoramaPath}`.quiet()
  // If the model ignored the 4:3 ratio and the resampled height falls short, the crop below
  // would silently PAD the image with background instead of cropping — reject that upfront.
  const size = await $`sips -g pixelHeight ${panoramaPath}`.text()
  const height = Number(size.match(/pixelHeight: (\d+)/)?.[1])
  if (!(height >= PANEL_HEIGHT)) {
    throw new Error(
      `Panorama is only ${TRIPTYCH_WIDTH}x${height} after resampling, needs ${PANEL_HEIGHT} of height`,
    )
  }
  await $`sips -c ${PANEL_HEIGHT} ${TRIPTYCH_WIDTH} ${panoramaPath}`.quiet()
}

const compositeScreenshots = async (triptych: Triptych, panoramaPath: string) => {
  console.log(`Triptych ${triptych.id}: compositing real screenshots onto magenta screens...`)
  const shots = triptych.panels.map((panel) => join(screenshotsDir, panel.source))
  await $`swift ${compositor} ${panoramaPath} ${shots[0]} ${shots[1]} ${shots[2]}`.quiet()
}

const slicePanorama = async (triptych: Triptych, panoramaPath: string) => {
  for (const [index, panel] of triptych.panels.entries()) {
    const panelPath = join(outputDir, panel.output)
    await $`cp ${panoramaPath} ${panelPath}`.quiet()
    // offsetY is 1 (not 0) because sips ignores an all-zero --cropOffset and falls back to a
    // centered crop; 1 gets clamped back to the top edge since the crop is full-height.
    await $`sips -c ${PANEL_HEIGHT} ${PANEL_WIDTH} --cropOffset 1 ${index * PANEL_WIDTH} ${panelPath}`.quiet()
    console.log(`Triptych ${triptych.id}: wrote ${panelPath}`)
  }
}

const requested = process.argv[2]
const triptychs = requested ? TRIPTYCHS.filter((t) => t.id === Number(requested)) : TRIPTYCHS
if (triptychs.length === 0) {
  console.error(`Unknown triptych "${requested}" (expected 1 or 2)`)
  process.exit(1)
}

await mkdir(outputDir, { recursive: true })
const workDir = await mkdtemp(join(tmpdir(), 'vinarium-previews-'))
for (const triptych of triptychs) {
  const panoramaPath = await generatePanorama(triptych, workDir)
  await normalizePanorama(panoramaPath)
  await compositeScreenshots(triptych, panoramaPath)
  await slicePanorama(triptych, panoramaPath)
}
console.log('Done.')
