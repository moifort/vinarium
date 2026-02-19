import { mkdir, readdir } from 'node:fs/promises'

const apiKey = process.env.NITRO_GOOGLE_API_KEY as string | undefined
if (!apiKey) {
  console.error('Missing NITRO_GOOGLE_API_KEY in environment. Load .env first.')
  process.exit(1)
}
const apiKeyStr: string = apiKey

const endpoint =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-image-preview:generateContent'

const SCREENSHOTS_DIR = 'generated/screenshots'
const MOCKUPS_DIR = 'generated/mockups'
const DELAY_MS = 3_000
const MAX_RETRIES = 3

// ---------------------------------------------------------------------------
// Design direction (prefixed to every prompt)
// ---------------------------------------------------------------------------

const designPrefix = `You are a senior iOS UI/UX designer. Redesign this screenshot from a premium wine cellar app called "Cave à Vin".

Design direction:
- Dark mode with warm accents (deep burgundy #8B1A2B, aged gold #C9A96E, warm cream #F5E6D3)
- Subtle glass morphism, depth and layered surfaces
- Elegant serif+sans-serif typography pairing, generous spacing
- Keep all French labels and text exactly as shown in the screenshot
- Pixel-perfect iOS rendering, iPhone resolution
- No explanatory text or annotations in the output image
- Output only the redesigned screen, nothing else

`

// ---------------------------------------------------------------------------
// Per-screen prompts
// ---------------------------------------------------------------------------

const screens: Array<{ file: string; prompt: string }> = [
  {
    file: '01-dashboard',
    prompt: `Redesign this Dashboard/home screen:
- Hero stat widgets: use rich background textures (cellar stone, wine barrels), overlay with translucent dark glass cards, large bold numbers in gold, subtle icon glow
- "Prêt à déguster" section: wine rows with color-coded dots, elegant card design with soft shadows
- "Journal" section: timeline-style layout with entry/exit icons, warm amber accents
- Overall: luxurious feel, magazine-quality layout with generous whitespace`,
  },
  {
    file: '02-cellar-grid',
    prompt: `Redesign this Cellar Grid screen:
- Section headers: elegant row labels (Rangée A, B...) with subtle divider lines
- Wine rows: card-based design with rounded corners, wine color indicator as a vertical accent bar on the left
- Position badges: styled as small stone-textured tags
- Add subtle depth with layered card backgrounds
- Empty space should feel like a physical wine rack`,
  },
  {
    file: '03-cellar-journal',
    prompt: `Redesign this Cellar Journal/history screen:
- Timeline layout: vertical line connecting events, circular markers for entry (green) and exit (red/amber)
- Event cards: glass-morphic with subtle blur, wine name prominent, date secondary
- Position badges with monospace font on dark pill background
- Smooth visual flow from newest to oldest event`,
  },
  {
    file: '04-wine-list',
    prompt: `Redesign this Wine List/catalog screen:
- Wine cards: horizontal layout with wine color as a prominent element (colored circle or vertical bar)
- Typography hierarchy: wine name bold, vintage and appellation secondary
- Subtle card separators or individual card backgrounds with soft rounded corners
- Search bar redesigned with glass morphism
- Premium feel, like a wine merchant's catalog`,
  },
  {
    file: '05-wine-detail',
    prompt: `Redesign this Wine Detail modal sheet:
- Hero section at top: wine name large, vintage prominent, wine color accent
- Info sections grouped in glass-morphic cards: details (appellation, region, grapes), drinking window, purchase info, notes
- Use warm gold for headings, cream for body text
- Rating display with elegant star or circle design
- Rounded sheet with drag indicator, layered depth`,
  },
  {
    file: '06-consumption-sheet',
    prompt: `Redesign this Consumption/tasting form sheet:
- Star rating: large, interactive, warm gold color
- Text field for tasting notes: elegant bordered area with placeholder text
- Date picker: clean, minimal
- Confirm button: prominent, gradient burgundy with subtle glow
- Form fields on glass-morphic card backgrounds
- Overall elegant and inviting, not clinical`,
  },
  {
    file: '07-scan-camera',
    prompt: `Redesign the camera/scan screen overlay (not the camera feed itself):
- Viewfinder frame: elegant gold corners or thin border with subtle animation suggestion
- Bottom action area: large capture button with glass-morphic background
- Helper text styled elegantly: "Photographiez l'étiquette"
- Dark vignette overlay around viewfinder area
- Minimal, focused interface that puts the camera center stage`,
  },
  {
    file: '08-scan-analyzing',
    prompt: `Redesign this loading/analyzing screen:
- Central animated indicator: elegant circular progress with wine glass or grape icon
- "Analyse en cours..." text: large, warm cream color, elegant font
- Subtle particle or shimmer effect suggestion in the background
- Dark background with very subtle texture (paper grain or leather)
- Calming, premium feeling while waiting`,
  },
  {
    file: '09-scan-review',
    prompt: `Redesign this scan review/verification form:
- Form fields grouped in glass-morphic sections: wine identity (name, color, vintage), origin (appellation, region), details (grapes, classification)
- Pre-filled values in warm cream, editable appearance
- Wine color selector: elegant horizontal chips with color fills
- Confirm button: prominent burgundy gradient
- Scrollable, spacious layout`,
  },
  {
    file: '10-scan-placement',
    prompt: `Redesign this cellar placement/position selection screen:
- Grid or visual representation of cellar positions
- Row/column selector: elegant picker or grid of tappable cells
- Selected position highlighted with gold accent
- Wine info summary at top (what's being placed)
- Visual rack metaphor: wooden or stone texture cells
- Clear, intuitive interaction for choosing position`,
  },
  {
    file: '11-scan-confirmation',
    prompt: `Redesign this success/confirmation screen:
- Large success indicator: elegant checkmark with subtle animation (golden glow or ring)
- Wine name and position displayed prominently
- Summary card with glass-morphic background
- "Done" or continue button: clean, satisfying
- Celebration feeling: subtle, classy, not overdone
- Dark background with warm accent lighting`,
  },
  {
    file: '12-empty-cellar',
    prompt: `Redesign this empty cellar state:
- Atmospheric illustration: empty wine rack or cellar archway in muted tones
- Inviting message: "Cave vide" styled elegantly
- Subtle call to action: "Ajoutez des bouteilles via le scanner"
- Dark, moody atmosphere with warm accent lighting
- Should feel like potential rather than emptiness
- Premium illustration quality`,
  },
  {
    file: '13-empty-wine-list',
    prompt: `Redesign this empty wine list state:
- Atmospheric illustration: empty shelf or wine glass silhouette
- "Aucun vin" message styled elegantly
- Inviting call to action to scan first wine
- Consistent with empty cellar style but distinct illustration
- Warm, encouraging mood
- Premium illustration quality`,
  },
]

// ---------------------------------------------------------------------------
// API call with retry
// ---------------------------------------------------------------------------

async function generateMockup(
  screenshotPath: string,
  prompt: string,
  outputPath: string,
): Promise<boolean> {
  const imageFile = Bun.file(screenshotPath)
  if (!(await imageFile.exists())) {
    console.error(`  ✗ Screenshot not found: ${screenshotPath}`)
    return false
  }

  const imageBuffer = await imageFile.arrayBuffer()
  const imageBase64 = Buffer.from(imageBuffer).toString('base64')
  const mimeType = screenshotPath.endsWith('.jpg') ? 'image/jpeg' : 'image/png'

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      console.log(`  Calling Gemini API${attempt > 1 ? ` (attempt ${attempt})` : ''}...`)

      const res = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'x-goog-api-key': apiKeyStr,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                { text: designPrefix + prompt },
                {
                  inline_data: {
                    mime_type: mimeType,
                    data: imageBase64,
                  },
                },
              ],
            },
          ],
          generationConfig: {
            responseModalities: ['TEXT', 'IMAGE'],
            imageConfig: {
              aspectRatio: '9:16',
              imageSize: '2K',
            },
          },
        }),
      })

      if (!res.ok) {
        const text = await res.text()
        if (res.status === 429 || res.status === 503) {
          const backoff = DELAY_MS * attempt
          console.error(`  Rate limited (${res.status}), waiting ${backoff / 1000}s...`)
          await new Promise((r) => setTimeout(r, backoff))
          continue
        }
        console.error(`  ✗ API error: ${res.status} ${text.slice(0, 200)}`)
        return false
      }

      const json = await res.json()
      const candidate = json.candidates?.[0]
      if (!candidate) {
        console.error(`  ✗ No candidates in response`)
        if (attempt < MAX_RETRIES) continue
        return false
      }

      const imagePart = candidate.content?.parts?.find(
        (p: { inlineData?: { data: string; mimeType: string } }) => p.inlineData,
      )
      if (!imagePart) {
        const textPart = candidate.content?.parts?.find((p: { text?: string }) => p.text)
        if (textPart?.text) {
          console.error(`  ✗ No image returned. Model said: ${textPart.text.slice(0, 200)}`)
        } else {
          console.error(`  ✗ No image in response`)
        }
        if (attempt < MAX_RETRIES) continue
        return false
      }

      const imageData = Buffer.from(imagePart.inlineData.data, 'base64')
      await Bun.write(outputPath, imageData)
      console.log(`  ✓ Saved: ${outputPath} (${(imageData.length / 1024).toFixed(0)} KB)`)
      return true
    } catch (err) {
      console.error(`  ✗ Error: ${err instanceof Error ? err.message : err}`)
      if (attempt < MAX_RETRIES) {
        await new Promise((r) => setTimeout(r, DELAY_MS * attempt))
        continue
      }
      return false
    }
  }
  return false
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  await mkdir(MOCKUPS_DIR, { recursive: true })

  // Check screenshots exist
  try {
    await readdir(SCREENSHOTS_DIR)
  } catch {
    console.error(`No screenshots found in ${SCREENSHOTS_DIR}/`)
    console.error('Run scripts/capture-screenshots.sh first.')
    process.exit(1)
  }

  // Allow filtering by screen name via CLI arg
  const filter = process.argv[2]

  let succeeded = 0
  let failed = 0

  for (const screen of screens) {
    if (filter && !screen.file.includes(filter)) continue

    const screenshotPath = `${SCREENSHOTS_DIR}/${screen.file}.png`
    const mockupPath = `${MOCKUPS_DIR}/${screen.file}-mockup.png`

    console.log(`\n━━━ ${screen.file} ━━━`)

    const ok = await generateMockup(screenshotPath, screen.prompt, mockupPath)
    if (ok) succeeded++
    else failed++

    // Rate limiting delay between calls
    await new Promise((r) => setTimeout(r, DELAY_MS))
  }

  console.log('\n══════════════════════════════════')
  console.log(`Done! ${succeeded} succeeded, ${failed} failed`)
  console.log(`Mockups saved to: ${MOCKUPS_DIR}/`)
}

main().catch(console.error)
