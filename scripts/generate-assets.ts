import { mkdir } from "node:fs/promises";

const apiKey = process.env.NITRO_GOOGLE_API_KEY;
if (!apiKey) {
  console.error("Missing NITRO_GOOGLE_API_KEY in environment. Load .env first.");
  process.exit(1);
}

const endpoint =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent";

async function generateImage(
  prompt: string,
  filename: string,
  aspectRatio = "1:1"
) {
  console.log(`Generating: ${filename}...`);
  const res = await fetch(endpoint, {
    method: "POST",
    headers: {
      "x-goog-api-key": apiKey!,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        responseModalities: ["TEXT", "IMAGE"],
        imageConfig: { aspectRatio },
      },
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    console.error(`Failed to generate ${filename}: ${res.status} ${text}`);
    return;
  }

  const json = await res.json();
  const candidate = json.candidates?.[0];
  if (!candidate) {
    console.error(`No candidates for ${filename}:`, JSON.stringify(json, null, 2));
    return;
  }

  const imagePart = candidate.content?.parts?.find(
    (p: { inlineData?: { data: string; mimeType: string } }) => p.inlineData
  );
  if (!imagePart) {
    console.error(`No image in response for ${filename}:`, JSON.stringify(candidate, null, 2));
    return;
  }

  const imageData = Buffer.from(imagePart.inlineData.data, "base64");
  await Bun.write(`generated/${filename}`, imageData);
  console.log(`  Saved: generated/${filename} (${imageData.length} bytes)`);
}

const designDirection =
  "Sober, refined, premium wine app aesthetic. Dark tones, subtle textures, elegant. No text, no cartoonish elements, photorealistic.";

const assets: Array<{ prompt: string; filename: string; aspect?: string }> = [
  {
    prompt: `Design a minimalist app icon for a premium wine cellar app. Wine glass silhouette, dark gradient background (deep burgundy to near-black). Clean, modern, matching iOS icon language. ${designDirection}`,
    filename: "app-icon.png",
  },
  {
    prompt: `Atmospheric wine cellar interior with wooden barrels, dark moody tones, dramatic lighting from above. Sharp and clear across the entire image, no blur, no vignette, no depth of field effects. Used as a small widget background. ${designDirection}`,
    filename: "widget-en-cave.png",
    aspect: "1:1",
  },
  {
    prompt: `Close-up of aged wine bottles stored in a wine rack, warm amber and golden lighting, shallow depth of field. Used as a small widget background. ${designDirection}`,
    filename: "widget-valeur.png",
    aspect: "1:1",
  },
  {
    prompt: `Elegant wine glass with warm golden light, beautiful bokeh background, dark ambiance. Used as a small widget background. ${designDirection}`,
    filename: "widget-pret-a-deguster.png",
    aspect: "1:1",
  },
  {
    prompt: `Vintage leather-bound journal or book with subtle wine stain accents, aged paper texture, dark moody lighting. Used as a small widget background. ${designDirection}`,
    filename: "widget-journal.png",
    aspect: "1:1",
  },
  {
    prompt: `Elegant empty wooden wine rack in a dark stone cellar, minimal and atmospheric. Clean composition for an empty state illustration. ${designDirection}`,
    filename: "empty-no-wines.png",
  },
  {
    prompt: `Empty stone cellar archway, atmospheric dark interior, moody lighting through the arch. Clean composition for an empty state illustration. ${designDirection}`,
    filename: "empty-no-cellar.png",
  },
];

async function main() {
  await mkdir("generated", { recursive: true });

  for (const asset of assets) {
    await generateImage(asset.prompt, asset.filename, asset.aspect);
    // Small delay to avoid rate limiting
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }

  console.log("\nDone! Check the generated/ directory.");
}

main().catch(console.error);
