const BASE_URL = process.env.TEST_SERVER_URL ?? 'http://localhost:3000'
const TOKEN = process.env.NITRO_API_TOKEN ?? '374CACE6-5E4E-456A-8BF7-93E689382C3C'

interface WineResponse {
  status: number
  data: { id: string; name: string; color: string }
}

async function api(method: string, path: string, body?: Record<string, unknown>) {
  const res = await fetch(`${BASE_URL}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  })
  if (!res.ok) {
    const text = await res.text()
    throw new Error(`${method} ${path} → ${res.status}: ${text}`)
  }
  return res.json()
}

const wines = [
  {
    name: 'Château Margaux',
    color: 'red',
    domain: 'Château Margaux',
    vintage: 2018,
    appellation: 'Margaux',
    region: 'Bordeaux',
    country: 'France',
    grapeVarieties: ['Cabernet Sauvignon', 'Merlot', 'Petit Verdot'],
    classification: 'Premier Grand Cru Classé',
    purchasePrice: 450,
    purchaseDate: '2022-06-15',
    drinkFrom: 2025,
    drinkUntil: 2060,
    notes: 'Nez complexe de cassis, violette et cèdre. Grand potentiel de garde.',
  },
  {
    name: 'Meursault 1er Cru Les Perrières',
    color: 'white',
    domain: 'Domaine Roulot',
    vintage: 2020,
    appellation: 'Meursault 1er Cru',
    region: 'Bourgogne',
    country: 'France',
    grapeVarieties: ['Chardonnay'],
    purchasePrice: 120,
    purchaseDate: '2023-03-10',
    drinkFrom: 2024,
    drinkUntil: 2035,
    notes: 'Minéralité saisissante, notes de noisette et de beurre frais.',
  },
  {
    name: 'Whispering Angel',
    color: 'rosé',
    domain: "Château d'Esclans",
    vintage: 2023,
    appellation: 'Côtes de Provence',
    region: 'Provence',
    country: 'France',
    grapeVarieties: ['Grenache', 'Cinsault', 'Rolle'],
    purchasePrice: 22,
    purchaseDate: '2024-04-20',
    drinkFrom: 2024,
    drinkUntil: 2026,
    notes: "Frais, élégant, parfait pour l'été.",
  },
  {
    name: 'Dom Pérignon',
    color: 'sparkling',
    domain: 'Moët & Chandon',
    vintage: 2013,
    appellation: 'Champagne',
    region: 'Champagne',
    country: 'France',
    grapeVarieties: ['Chardonnay', 'Pinot Noir'],
    purchasePrice: 200,
    purchaseDate: '2023-12-01',
    drinkFrom: 2024,
    drinkUntil: 2040,
    notes: "Bulle fine et persistante, notes de brioche et d'agrumes confits.",
  },
  {
    name: "Château d'Yquem",
    color: 'sweet',
    domain: "Château d'Yquem",
    vintage: 2015,
    appellation: 'Sauternes',
    region: 'Bordeaux',
    country: 'France',
    grapeVarieties: ['Sémillon', 'Sauvignon Blanc'],
    classification: 'Premier Cru Supérieur',
    purchasePrice: 350,
    purchaseDate: '2021-11-05',
    drinkFrom: 2025,
    drinkUntil: 2070,
    notes: "Or intense, abricot confit, miel d'acacia, longueur exceptionnelle.",
  },
  {
    name: 'Châteauneuf-du-Pape Hommage à Jacques Perrin',
    color: 'red',
    domain: 'Château de Beaucastel',
    vintage: 2019,
    appellation: 'Châteauneuf-du-Pape',
    region: 'Vallée du Rhône',
    country: 'France',
    grapeVarieties: ['Mourvèdre', 'Grenache', 'Syrah', 'Counoise'],
    purchasePrice: 280,
    purchaseDate: '2023-09-18',
    drinkFrom: 2026,
    drinkUntil: 2050,
    notes: 'Puissant et raffiné, épices, garrigue, fruits noirs concentrés.',
  },
]

const positions = ['A', 'B', 'C', 'D', 'E', 'F']

async function main() {
  console.log('Resetting database...')
  await api('POST', '/test/reset')

  console.log('\nCreating wines and placing in cellar...')
  const createdWines: Array<{ id: string; name: string }> = []

  for (let i = 0; i < wines.length; i++) {
    const wine = wines[i]
    const res = (await api('POST', '/wines', wine)) as WineResponse
    const id = res.data.id
    createdWines.push({ id, name: wine.name })
    console.log(`  ✓ ${wine.name} → ${id}`)

    await api('POST', '/cellar/place', {
      wineId: id,
      row: positions[i],
      col: 1,
    })
    console.log(`    Placed at ${positions[i]}1`)
  }

  // Remove the rosé with a tasting note (for journal history)
  const rose = createdWines[2]
  console.log(`\nRemoving ${rose.name} with tasting note...`)
  await api('POST', '/cellar/remove', {
    wineId: rose.id,
    rating: 4,
    consumedDate: new Date().toISOString(),
    tastingNotes:
      'Très agréable, robe pâle saumonée. Arômes de pêche blanche et de fleurs. Finale saline et rafraîchissante.',
  })
  console.log(`  ✓ Removed with rating 4/5`)

  console.log('\nDone! Database seeded with:')
  console.log(`  - ${wines.length} wines created`)
  console.log(`  - ${wines.length - 1} bottles in cellar (positions A1-F1, rosé removed)`)
  console.log('  - 1 tasting note in journal')
}

main().catch((err) => {
  console.error('Error:', err.message)
  process.exit(1)
})
