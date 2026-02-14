# Plan : Backend Cave à Vin (API uniquement)

## Contexte

Construire le backend de l'application Cave à Vin : des API routes Nitro pour gérer les bouteilles, scanner des étiquettes via Claude Vision, gérer les emplacements dans une grille, obtenir des conseils IA, et consulter l'état financier. Pas de frontend pour l'instant — tests via `api.http`.

## Stack

- Nitro (H3), TypeScript strict, Bun, Biome
- `ts-brand` + Zod pour la validation
- `ts-pattern` pour le pattern matching
- Nitro `useStorage` avec driver FS (`.data/db/`)
- API Anthropic Claude (claude-sonnet-4-5 vision)

## Structure serveur

```
server/
├── types.ts                # Types partagés entre domaines (Eur, etc.)
├── primitives.ts           # Validateurs partagés entre domaines (Eur(), etc.)
├── wine/                   # Domaine "wine"
│   ├── types.ts
│   ├── primitives.ts
│   └── index.ts            # namespace Wines
├── cellar/                 # Domaine "cellar"
│   ├── types.ts
│   ├── primitives.ts
│   └── index.ts            # namespace Cellar
├── finance/                # Domaine "finance"
│   ├── types.ts
│   └── index.ts            # namespace Finance
├── ai/                     # Domaine "ai" (scan + conseils)
│   ├── types.ts
│   ├── primitives.ts
│   └── index.ts            # namespace AI
├── config/
│   ├── types.ts
│   ├── primitives.ts
│   └── index.ts            # config() factory
├── tasks/
│   └── finance/
│       └── snapshot.ts     # Nitro scheduled task (1er du mois)
├── routes/
│   ├── wines/
│   │   ├── index.get.ts
│   │   ├── index.post.ts
│   │   ├── scan.post.ts
│   │   ├── [id].get.ts
│   │   ├── [id].put.ts
│   │   ├── [id].delete.ts
│   │   └── [id]/
│   │       ├── consume.post.ts
│   │       └── position.post.ts
│   ├── cellar/
│   │   ├── config.get.ts
│   │   ├── config.put.ts
│   │   └── grid.get.ts
│   ├── finances/
│   │   └── summary.get.ts
│   └── advice.post.ts
```

## Types partagés (`server/types.ts` + `server/primitives.ts`)

Types communs utilisés par plusieurs domaines.

### `server/types.ts`

```typescript
import type { Brand } from 'ts-brand'

export type Eur = Brand<number, 'Eur'>  // montant en euros
```

### `server/primitives.ts`

```typescript
import { make } from 'ts-brand'
import { z } from 'zod'
import type { Eur as EurType } from './types'

export const Eur = (value: unknown) => {
  const v = z.preprocess(
    (v) => (typeof v === 'string' ? Number(v) : v),
    z.number().nonnegative(),
  ).parse(value)
  return make<EurType>()(v)
}
```

## Domaine `wine`

### `server/wine/types.ts`

```typescript
import type { Brand } from 'ts-brand'

export type WineId = Brand<string, 'WineId'>
export type WineName = Brand<string, 'WineName'>
export type Vintage = Brand<number, 'Vintage'>
export type AlcoholContent = Brand<number, 'AlcoholContent'>
export type WineColor = 'red' | 'white' | 'rosé' | 'sparkling' | 'sweet'
export type WineStatus = 'in_cellar' | 'consumed' | 'gifted'

export type Wine = {
  id: WineId
  name: WineName
  domain: string | null
  vintage: Vintage | null
  appellation: string | null
  region: string | null
  country: string | null
  color: WineColor
  grapeVarieties: string[]
  alcoholContent: AlcoholContent | null
  classification: string | null
  position: { row: number; col: number } | null
  purchasePrice: Eur | null
  purchaseDate: string | null
  drinkFrom: number | null
  drinkUntil: number | null
  imageBase64: string | null
  notes: string
  status: WineStatus
  consumedDate: string | null
  createdAt: string
  updatedAt: string
}
```

### `server/wine/primitives.ts`

```typescript
import { make } from 'ts-brand'
import { z } from 'zod'
import type { WineId as WineIdType, WineName as WineNameType, Vintage as VintageType, AlcoholContent as AlcoholContentType } from './types'

export const WineId = (value: unknown) => {
  const v = z.string().uuid().parse(value)
  return make<WineIdType>()(v)
}

export const randomWineId = () => WineId(crypto.randomUUID())

export const WineName = (value: unknown) => {
  const v = z.string().min(1).parse(value)
  return make<WineNameType>()(v)
}

export const Vintage = (value: unknown) => {
  const v = z.preprocess(
    (v) => (typeof v === 'string' ? Number(v) : v),
    z.number().int().min(1800).max(new Date().getFullYear()),
  ).parse(value)
  return make<VintageType>()(v)
}

export const AlcoholContent = (value: unknown) => {
  const v = z.preprocess(
    (v) => (typeof v === 'string' ? Number(v) : v),
    z.number().min(0).max(25),
  ).parse(value)
  return make<AlcoholContentType>()(v)
}

```

### `server/wine/index.ts` — namespace `Wines`

```typescript
export namespace Wines {
  // Wines.create(data) → Wine
  // Wines.getById(id) → Wine | 'not-found'
  // Wines.list(filters?) → Wine[]
  // Wines.update(id, data) → Wine | 'not-found'
  // Wines.remove(id) → 'ok' | 'not-found'
  // Wines.consume(id) → Wine | 'not-found' | 'already-consumed'
  // Wines.setPosition(id, row, col) → Wine | 'not-found' | 'position-taken'
}
```

Storage bucket : `useStorage('wines')` → `.data/db/wines/{id}.json`

## Domaine `cellar`

### `server/cellar/types.ts`

```typescript
import type { Brand } from 'ts-brand'

export type CellarRows = Brand<number, 'CellarRows'>
export type CellarCols = Brand<number, 'CellarCols'>

export type CellarConfig = {
  rows: CellarRows
  cols: CellarCols
  name: string
}
```

### `server/cellar/index.ts` — namespace `Cellar`

```typescript
export namespace Cellar {
  // Cellar.getConfig() → CellarConfig (avec défaut si inexistant)
  // Cellar.updateConfig(data) → CellarConfig
  // Cellar.getGrid() → (Wine | null)[][] — matrice rows×cols avec les bouteilles placées
}
```

Storage bucket : `useStorage('cellar')` → `.data/db/cellar/`

## Domaine `finance`

### `server/finance/types.ts`

```typescript
import type { Eur } from '~/types'

export type FinanceSummary = {
  currentValue: Eur          // valeur actuelle de la cave (somme des prix d'achat in_cellar)
  bottleCount: number
  averagePrice: Eur          // prix moyen par bouteille
  byColor: Record<string, { count: number; value: Eur }>
  byRegion: Record<string, { count: number; value: Eur }>
  byPriceRange: { range: string; count: number }[]
  monthlyHistory: {
    month: string            // "2025-01"
    cellarValue: Eur         // valeur de la cave en fin de mois
    entriesCount: number
    entriesValue: Eur        // valeur des achats
    exitsCount: number
    exitsValue: Eur          // valeur des sorties
  }[]
  trend: {
    lastMonthDelta: Eur      // variation vs mois précédent
    last3MonthsDelta: Eur    // variation sur 3 mois
    last12MonthsDelta: Eur   // variation sur 12 mois
  }
}
```

### `server/finance/index.ts` — namespace `Finance`

```typescript
export namespace Finance {
  // Finance.getSummary() → FinanceSummary
  //   - Lit toutes les bouteilles (in_cellar + consumed + gifted) via Wines.list()
  //   - currentValue = somme des purchasePrice des bouteilles in_cellar
  //   - Répartitions par couleur, région, tranche de prix (sur les in_cellar uniquement)
  //   - Historique mensuel : reconstitue la valeur de la cave mois par mois
  //     en parcourant purchaseDate (entrées) et consumedDate (sorties)
  //   - Trend : calcule les deltas 1 mois / 3 mois / 12 mois pour savoir
  //     si la cave monte ou descend en valeur
}
```

### Persistance mensuelle via Nitro Task

Un snapshot financier est calculé et persisté **chaque mois** via une tâche Nitro planifiée.

Fichier : `server/tasks/finance/snapshot.ts`

```typescript
export default defineTask({
  meta: {
    name: 'finance:snapshot',
    description: 'Calcule et persiste le snapshot financier mensuel de la cave',
  },
  run() {
    // Appelle Finance.computeAndSaveSnapshot()
    // Stocke dans useStorage('finance') → .data/db/finance/snapshots/{YYYY-MM}.json
    return { result: 'Success' }
  },
})
```

Config dans `nuxt.config.ts` :

```typescript
nitro: {
  experimental: { tasks: true },
  scheduledTasks: {
    '0 0 1 * *': ['finance:snapshot']  // 1er de chaque mois à minuit
  }
}
```

Storage bucket : `useStorage('finance')` → `.data/db/finance/`

`Finance.getSummary()` lit les snapshots persistés pour l'historique + calcule les données live pour le mois en cours.

## Domaine `ai`

### `server/ai/index.ts` — namespace `AI`

```typescript
export namespace AI {
  // AI.scanLabel(imageBuffer: Buffer) → données structurées du vin (appel Claude Vision avec tool use)
  // AI.getAdvice(wines: Wine[], occasion?: string) → string (recommandations textuelles)
}
```

Appelle l'API Anthropic via `$fetch`. La clé API vient de `config().anthropicApiKey`.

Le scan utilise le tool use de Claude pour retourner des données structurées (pas de parsing texte libre). L'IA estime aussi `drinkFrom`/`drinkUntil`.

## Config

### `server/config/types.ts`

```typescript
import type { Brand } from 'ts-brand'
export type AnthropicApiKey = Brand<string, 'AnthropicApiKey'>
```

### `server/config/index.ts`

```typescript
export const config = () => {
  const runtimeConfig = useRuntimeConfig()
  return {
    anthropicApiKey: AnthropicApiKey(runtimeConfig.anthropicApiKey),
  }
}
```

## Configuration Nitro (`nuxt.config.ts`)

```typescript
nitro: {
  storage: {
    wines: { driver: 'fs', base: './.data/db/wines' },
    cellar: { driver: 'fs', base: './.data/db/cellar' },
    finance: { driver: 'fs', base: './.data/db/finance' },
  }
},
runtimeConfig: {
  anthropicApiKey: '' // via ANTHROPIC_API_KEY env var
}
```

## Routes (orchestrateurs minimaux)

Chaque route suit le pattern : extract → validate → call namespace → match errors → respond.

Exemple `server/routes/wines/[id].get.ts` :

```typescript
import { Wines } from '~/wine/index'
import { WineId } from '~/wine/primitives'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const wine = await Wines.getById(id)
  if (wine === 'not-found')
    throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  return { status: 200, data: wine }
})
```

Exemple `server/routes/wines/scan.post.ts` :

```typescript
import { AI } from '~/ai/index'

export default defineEventHandler(async (event) => {
  const body = await readRawBody(event, false)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'No image provided' })
  const result = await AI.scanLabel(Buffer.from(body))
  return { status: 200, data: result }
})
```

## Dépendances à installer

```bash
bun add ts-brand zod ts-pattern
```

## Ordre d'implémentation

1. **Dépendances + Config** — installer ts-brand/zod/ts-pattern, `nuxt.config.ts` (storage + runtimeConfig), `server/config/`
2. **Domaine wine** — types.ts, primitives.ts, index.ts (namespace Wines avec CRUD)
3. **Routes CRUD wines** — les 5 routes GET/POST/PUT/DELETE + consume + position
4. **Domaine ai** — types.ts, index.ts (namespace AI avec scanLabel)
5. **Route scan** — scan.post.ts
6. **Domaine cellar** — types.ts, primitives.ts, index.ts (namespace Cellar)
7. **Routes cellar** — config + grid
8. **Domaine finance + Route** — types.ts, index.ts (namespace Finance) + summary.get.ts
9. **Route advice** — advice.post.ts

Mettre à jour `api.http` à chaque étape pour tester.

## Vérification

- `bun run dev` puis tester chaque endpoint via `api.http`
- Vérifier les fichiers JSON dans `.data/db/`
- Tester le scan avec `images/IMG_3187.jpeg`
- `bun run typecheck`
- `bunx biome check .`
