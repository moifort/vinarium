# Design: Scan Enrichment, Universal Wine Detail, UI Improvements & App Icon

**Date**: 2026-02-15

## Feature 1: Enrichissement web du scan via Gemini Grounding

### Objectif
Améliorer la précision des données extraites lors du scan d'étiquette en complétant l'analyse visuelle de Claude par une recherche web via Gemini avec Google Search grounding.

### Architecture
Deux passes séquentielles :
1. **Passe 1 (Claude Sonnet)** : Analyse l'image de l'étiquette, extrait les données visuelles (nom, domaine, vintage, appellation, couleur, alcool, etc.) — comportement existant.
2. **Passe 2 (Gemini + Google Search)** : Reçoit les données extraites par Claude et recherche sur le web pour affiner/compléter : prix de marché, fenêtre de garde optimale, cépages, classification, informations complémentaires.
3. **Merge** : Les données visuelles de Claude ont priorité. Gemini complète uniquement les champs manquants ou les estimations (prix, garde, cépages non visibles sur l'étiquette).

### Changements backend
- Ajouter `googleApiKey` dans `server/config/` (runtime config)
- Créer `AI.enrichWithSearch(scanResult: ScanResult)` dans `server/ai/index.ts`
- Modifier `server/routes/wines/scan.post.ts` pour appeler enrichWithSearch après scanLabel

### Modèle Gemini
- Endpoint: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent`
- Activer `google_search` comme tool pour le grounding

---

## Feature 2: Sheet universelle de détail vin avec domaine agrégateur

### Objectif
Partout où un vin est affiché en ligne (Dashboard, Cave, Journal, Liste des vins), un tap ouvre une sheet avec le détail complet et exhaustif du vin. Même contenu partout.

### Architecture backend — Domaine `user-wine`
Nouveau domaine agrégateur sans stockage propre :
- `server/user-wine/index.ts` : Namespace `UserWine` avec fonction `getDetail(wineId)`
- `server/user-wine/types.ts` : Type `UserWineDetail` (agrégation complète)
- `server/routes/user-wine/[id].get.ts` : Route `GET /api/user-wine/:id`

Le domaine `UserWine.getDetail()` appelle :
- `Wines.getById(id)` — données du vin
- `Cellar.getEntry(wineId)` — position et historique en cave

Retourne un objet `UserWineDetail` avec toutes les données consolidées.

### Architecture iOS
- Nouveau modèle `UserWineDetail` dans `Models/`
- Nouveau endpoint `UserWineAPI.get(id:)` dans `API/`
- Nouvelle `WineDetailSheet` — sheet universelle de détail basée sur le contenu actuel de `WineDetailView`
- Remplacement de `CellDetailSheet` par cette sheet universelle
- Ajout de la sheet dans : `DashboardView` (vins à boire, cartes activité), `CellarJournalView` (événements), `WineListView` (remplacement du NavigationLink actuel)

### Contenu de la sheet (exhaustif)
- Header : nom, couleur, domaine, millésime
- Origine : appellation, région, pays, classification
- Détails : alcool, prix d'achat, date d'achat, cépages
- Garde : à partir de, jusqu'à
- Position en cave (si en cave) + bouton retirer
- Historique de consommation (si sorti) + note + commentaire
- Notes personnelles

---

## Feature 3: Bouton Liquid Glass rond pour la galerie photo

### Objectif
Remplacer le bouton "Galerie" capsule actuel par un bouton rond Liquid Glass (iOS 26) avec une icône photo.

### Changements
- Dans `ContentView.swift` (ScanFlowView), remplacer le `PhotosPicker` actuel (style capsule avec label texte) par un `PhotosPicker` avec :
  - Icône SF Symbol `photo` (pas de texte)
  - Style rond (`.clipShape(Circle())`)
  - Effet `.glassEffect` (Liquid Glass iOS 26)
  - Taille ~44pt
  - Position : bas gauche de l'écran caméra

---

## Feature 4: Génération de l'icône avec Imagen 3

### Objectif
Générer l'icône de l'app via l'API Gemini (Imagen 3).

### Approche
- Script one-shot appelant l'API Imagen 3
- Prompt : bouteilles de vin vues du dessus en quinconce, style adapté à une icône d'app iOS
- Format : PNG 1024x1024
- Destination : `ios/CaveAVin/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- Mise à jour du `Contents.json` pour référencer l'image

### API
- Endpoint Gemini Imagen 3
- Clé API fournie par l'utilisateur
