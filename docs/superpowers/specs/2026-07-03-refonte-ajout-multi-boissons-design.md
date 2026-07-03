# Refonte du flow d'ajout + support multi-boissons

**Date** : 2026-07-03
**Statut** : en attente de validation utilisateur

## Objectifs

1. **Flow d'ajout intuitif** : au moment de l'ajout d'une bouteille (après l'analyse IA), l'utilisateur choisit explicitement la destination — cave, favori, à retenir, conseillé par un ami — via un écran dédié, au lieu des boutons de toolbar actuels peu visibles.
2. **Multi-boissons** : l'app gère vin, spiritueux, bière, saké, cidre (et « autre »), y compris dans l'analyse IA des étiquettes.

## Décisions validées / hypothèses

- ✅ **Validé par l'utilisateur** : choix de la destination **avant** le formulaire, juste après l'analyse IA ; le formulaire s'adapte ensuite à la destination.
- ⚠️ **Hypothèse à confirmer** (question restée sans réponse) : types de boissons en **liste fermée** (`wine | spirit | beer | sake | cider | other`) avec **champs adaptés par type**, détection automatique du type par l'IA au scan.

## Approches envisagées

| Approche | Verdict |
|---|---|
| **A. Discriminant léger sur `Wine`** : champ `beverageType` + quelques champs génériques, collection `wines` conservée | ✅ **Retenue** — évolution incrémentale, réutilise tout l'existant (statuts, cave, tasting, gift, reco) |
| B. Domaines séparés par boisson (`spirit/`, `beer/`…) | ❌ Duplication massive de commands/queries/repos ; cave/favoris/journal sont transverses par nature |
| C. Enum de type mais formulaire 100 % générique | ❌ Perd la richesse actuelle du vin (cépages, appellation, garde) sans vrai gain |

## Design

### 1. Modèle de domaine (backend)

`server/domain/wine/types.ts` :

```ts
export type BeverageType = 'wine' | 'spirit' | 'beer' | 'sake' | 'cider' | 'other'

export type Wine = {
  // ...existant
  beverageType: BeverageType   // requis, backfillé par migration
  color?: WineColor            // devient optionnel — pertinent uniquement pour le vin
  style?: BeverageStyle        // nouveau, branded — « IPA », « Single Malt », « Junmai »…
  alcoholContent?: number      // nouveau — degré d'alcool (% vol), toutes boissons
}
```

- `beverageType` est **requis** dans le domaine : le statut « vin par défaut » n'existe que le temps de la migration.
- `color` devient optionnel : un whisky n'a pas de « couleur de vin ». Règle métier : `color` exigé si `beverageType === 'wine'` (validation dans `primitives.ts`/`business-rules.ts`).
- `domain` (producteur) garde son nom mais sa sémantique s'élargit : domaine / distillerie / brasserie / kura. Pas de renommage `Wine → Beverage` (churn énorme, zéro gain fonctionnel — YAGNI).
- Champs spécifiques vin (`grapeVarieties`, `appellation`, `classification`, `vintage`, `drinkFrom/Until`, `servingTemperature`) restent optionnels et sont simplement non renseignés pour les autres types.
- `WineStatus`, cellar, tasting, gift, recommendation, journal : **inchangés** (agnostiques au type de boisson).

Sémantique des champs par type (pilote le formulaire iOS et le prompt IA) :

| Champ | wine | spirit | beer | sake | cider | other |
|---|---|---|---|---|---|---|
| color | ✅ requis | — | — | — | — | — |
| style | — | ✅ (Single Malt…) | ✅ (IPA…) | ✅ (Junmai…) | ✅ | ✅ |
| grapeVarieties, appellation, classification, drinkFrom/Until, servingTemperature | ✅ | — | — | — | — | — |
| vintage | ✅ | ✅ (embouteillage) | — | — | — | — |
| alcoholContent, domain, region, country, prix, notes, giftedBy, geo | ✅ tous types | | | | | |

### 2. Migration Firestore

- `server/system/migration/migrations/0001-backfill-beverage-type.ts` (première migration réelle) : sur la collection `wines`, écrire `beverageType: 'wine'` sur tout doc qui n'en a pas. Enregistrée dans `migrations/index.ts`, déclenchée par `POST /admin/migrate`.
- Le cache `scan-cache` n'est **pas** migré : `parseScanResponse` applique `beverageType: 'wine'` par défaut sur les résultats cachés anciens (Zod `.default('wine')`).

### 3. Analyse IA (scan Gemini)

`server/system/scan/index.ts` :

- **Prompt généralisé** : « Analyse cette image d'étiquette de boisson (vin, spiritueux, bière, saké, cidre…) », consignes conditionnelles par type (cépages/garde uniquement si vin ; style si bière/spiritueux/saké…).
- **`responseSchema`** : ajoute `beverageType` (enum, requis), `style` (nullable), `alcoholContent` (nullable) ; `color` passe **nullable** (Gemini ne supporte pas le « requis conditionnel » — le prompt exige la couleur pour un vin, la règle métier la valide côté serveur).
- **`required`** : `['name', 'beverageType']`.
- **Enrichissement web** (`enrichWithSearch`) : la description envoyée inclut le type de boisson ; les champs demandés s'adaptent (pas de cépages pour une bière ; style et degré demandés pour spiritueux/bière/saké).
- `ScanResult` (`types.ts`) : `+ beverageType`, `+ style`, `+ alcoholContent`, `color` optionnel.

### 4. GraphQL (Pothos)

- Nouvel enum `BeverageTypeEnum` (`server/domain/wine/infrastructure/graphql/enums.ts`).
- `WineType` : `+ beverageType`, `+ style`, `+ alcoholContent` ; `color` devient nullable.
- `AddWineInput` / `UpdateWineInput` : `+ beverageType` (optionnel côté API, défaut `wine` pour compatibilité de l'app déployée), `+ style`, `+ alcoholContent`.
- `ScanResultType` : `+ beverageType`, `+ style`, `+ alcoholContent`, `color` nullable.
- Régénérer `shared/schema.graphql` (`bun run generate:graphql`) puis le code Apollo iOS (`apollo-ios-cli generate`).

### 5. iOS — nouveau flow d'ajout

Machine à états `ScanStep` : `camera → scanning → `**`destination`**` → review → placing (cave uniquement) → confirmed`.

**Nouvel écran `ScanDestinationPage`** (`Features/Scan/components/pages/`) :
- En-tête : résumé de l'analyse — nom, badge type de boisson, couleur/style, millésime.
- 4 grandes cartes : 🍷 **Ma cave** · ❤️ **Favori** · 🔖 **À retenir** · 👤 **Conseillé par un ami**.
- Vue primitive-first (String/enum/closures), previewable sans serveur.

**`ScanReviewPage` refondu** :
- Reçoit la destination choisie ; titre et CTA adaptés (« Ajouter à la cave », « Ajouter aux favoris »…).
- Un seul bouton d'action principal — les 4 boutons de toolbar disparaissent.
- Les sheets actuelles (`FavoriteSheet`, `ShortlistSheet`, `RecommendationSheet`) deviennent des **sections inline** du formulaire selon la destination (date/contacts/notes pour favori ; rating pour à retenir ; nom de l'ami + commentaire pour conseillé).
- **Champs conditionnels par type de boisson** : picker du type (corrigible si l'IA s'est trompée) ; les sections vin (couleur, cépages, appellation, garde) n'apparaissent que pour `wine` ; champ style pour les autres ; libellé du producteur adapté (Domaine/Distillerie/Brasserie…).
- Possibilité de **changer de destination** (retour à l'écran destination).

**Modèles iOS** : `BeverageType` (enum Sendable + mapping GraphQL), `Wine.beverageType/style/alcoholContent`, `WineColor` optionnel, `ScanResult` enrichi, `CreateWineRequest` étendu.

**Affichage existant** : partout où la couleur sert de badge (cave, listes, dashboard), fallback sur une icône/badge du type de boisson quand `color == nil`. Pas d'autre refonte des listes (filtres par type de boisson = hors périmètre, itération future).

### 6. Gestion d'erreurs

- Backend : unions discriminées existantes ; nouvelle erreur de validation `color requis pour un vin` sur `addWine`/`updateWine`.
- Scan : si l'IA ne détermine pas le type → `other` (jamais d'échec du scan pour cette raison) ; l'utilisateur corrige via le picker.

### 7. Tests

- `business-rules.unit.test.ts` : règle `color requis si vin`, couverture 100 % (pattern projet).
- Tests unitaires scan : parsing du nouveau schéma, défaut `wine` sur cache ancien, défaut `other`.
- Migration : test avec `fake-firestore` (backfill + atomicité/batches).
- iOS : previews de `ScanDestinationPage` et des variantes du formulaire par type/destination.

### 8. Hors périmètre (itérations futures)

- Filtres/tri par type de boisson dans les listes et le dashboard.
- Champs très spécialisés (âge des spiritueux, IBU bière, polissage saké).
- Renommage `Wine → Beverage` dans le code et Firestore.

## Ordre d'implémentation

1. Backend domaine : types + primitives + business-rules + migration (TDD).
2. Scan : prompt + schéma + parsing (TDD).
3. GraphQL : enums/types/inputs + codegen schéma partagé.
4. iOS : modèles + codegen Apollo → `ScanDestinationPage` → refonte `ScanReviewPage` → adaptations d'affichage.
5. Vérifications : `bun tsc --noEmit`, `bun test`, `bunx biome check`, build Xcode.
