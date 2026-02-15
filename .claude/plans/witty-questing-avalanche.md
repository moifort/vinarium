# Plan : 5 fonctionnalites cave-a-vin

## Contexte

L'application a une page Cave avec une grille 2D peu lisible, un scan qui ne permet pas de choisir une photo existante, une liste de vins sans acces rapide aux favoris, pas de page d'accueil, et pas d'historique visuel. Ces 5 features ameliorent l'UX globale.

**Limitation connue** : le stockage cellar utilise `entries:{wineId}` comme cle, un vin replace ecrase son entree precedente. La timeline refletera l'etat actuel des entrees (dernier placement/sortie par vin).

---

## Feature 1 : Redesign page Cave en liste groupee

**Fichiers modifies :**
- `ios/CaveAVin/Models/CellarModels.swift` — ajout `CellarRowGroup` et `CellarRowItem`
- `ios/CaveAVin/Features/Cellar/CellarGridViewModel.swift` — ajout computed property `groupedRows`
- `ios/CaveAVin/Features/Cellar/CellarGridView.swift` — remplacer `CellarGridComponent` par `List` groupee

**Backend** : aucun changement, on reutilise `GET /cellar/grid`

**Implementation :**

1. Dans `CellarModels.swift`, ajouter :
   ```swift
   struct CellarRowGroup: Identifiable, Sendable { row: String, items: [CellarRowItem] }
   struct CellarRowItem: Identifiable, Sendable { position: String, wine: Wine, rowIndex: Int, colIndex: Int }
   ```

2. Dans `CellarGridViewModel.swift`, ajouter computed property `groupedRows` qui transforme `grid: [[GridCell]]` en tableau de `CellarRowGroup`, filtrant les cellules vides

3. Dans `CellarGridView.swift` :
   - Remplacer `CellarGridComponent` par un `List` avec `ForEach(viewModel.groupedRows)` -> sections
   - Section header : `Label("Rangee X", systemImage: "cabinet")`
   - Chaque item : `HStack { WineColorBadge | nom + millesime | Spacer | badge position (ex: A2) }`
   - Tap sur un item -> ouvre `CellDetailSheet` existant (conserve le flow de retrait via `ConsumptionSheet`)
   - Swipe action `.trailing` avec bouton "Retirer" qui ouvre directement le `CellDetailSheet`
   - Etat vide : `ContentUnavailableView("Cave vide", ...)`

**Note** : `CellarGridComponent.swift` n'est PAS supprime car utilise par `PlacementView.swift`

---

## Feature 2 : PhotosPicker dans la page Scan

**Fichiers modifies :**
- `ios/CaveAVin/ContentView.swift` — modifier `ScanFlowView`

**Backend** : aucun changement, `POST /wines/scan` accepte deja du binaire

**Implementation :**

1. `import PhotosUI` en haut du fichier
2. Ajouter `@State private var selectedPhoto: PhotosPickerItem?` dans `ScanFlowView`
3. Dans le case `.camera`, wrapper `CameraView` dans un `ZStack` et ajouter un `PhotosPicker` en overlay en bas a gauche (au-dessus du bouton capture), style capsule avec material blur
4. `.onChange(of: selectedPhoto)` : charger l'image via `loadTransferable(type: Data.self)`, convertir en JPEG via `UIImage` -> `jpegData(compressionQuality: 0.8)`, appeler `viewModel.capturePhoto(jpeg)`

---

## Feature 3 : Top vins (5 etoiles) dans la liste

**Fichiers modifies :**
- `ios/CaveAVin/Features/WineList/WineListView.swift` — ajout bouton toolbar

**Backend** : aucun changement, `GET /wines?minRating=5` fonctionne deja

**Implementation :**

1. Ajouter un `ToolbarItem(placement: .topBarLeading)` avec un bouton etoile
2. Toggle : si `viewModel.minRating == 5` -> met a `0`, sinon met a `5`
3. Icone : `star.fill` jaune quand actif, `star` quand inactif
4. Le `onChange(of: viewModel.minRating)` existant declenchera le reload

---

## Feature 4 : Page d'accueil (Dashboard)

**Fichiers backend a creer :**
- `server/routes/dashboard/index.get.ts` — route GET /dashboard

**Fichiers backend a modifier :**
- `server/cellar/index.ts` — ajouter `getAllEntries()` (sans filtre `dateOut`)

**Fichiers iOS a creer :**
- `ios/CaveAVin/Models/DashboardModels.swift` — `DashboardData`, `DashboardWine`, `DashboardEntry`
- `ios/CaveAVin/API/DashboardAPI.swift` — appel `GET /dashboard`
- `ios/CaveAVin/Features/Dashboard/DashboardView.swift` — vue + viewmodel inline ou separe
- `ios/CaveAVin/Features/Dashboard/DashboardViewModel.swift`

**Fichiers iOS a modifier :**
- `ios/CaveAVin/ContentView.swift` — ajouter tab "Accueil" en premiere position

**Implementation backend :**

1. Dans `server/cellar/index.ts`, ajouter `getAllEntries` (copie de `getActiveEntries` sans le `.filter(e => !e.dateOut)`)
2. Route `GET /dashboard` :
   - `bottleCount` : nombre d'entrees actives
   - `readyToDrink` : vins actifs ou `drinkFrom <= annee courante <= drinkUntil`
   - `lastEntry` : entree avec `dateIn` la plus recente (toutes entrees)
   - `lastExit` : entree avec `dateOut` la plus recente
   - Retourne les infos vin (nom, couleur, domaine, millesime) + position + date

**Implementation iOS :**

1. Models : `DashboardData { bottleCount, readyToDrink: [DashboardWine], lastEntry/lastExit: DashboardEntry? }`
2. Vue : `ScrollView` avec cartes :
   - Carte metrique : nombre de bouteilles (grand chiffre)
   - Section "A boire maintenant" : liste des vins dans leur fenetre de degustation
   - Carte "Derniere entree" : icone verte, nom vin, position, date
   - Carte "Derniere sortie" : icone rouge, nom vin, position, date, rating si present
3. Tab dans ContentView : `Tab("Accueil", systemImage: "house")` en premiere position

---

## Feature 5 : Journal visuel (timeline) dans la page Cave

**Fichiers backend a creer :**
- `server/routes/cellar/history.get.ts` — route GET /cellar/history

**Fichiers backend a modifier :**
- `server/cellar/index.ts` — ajouter `getHistory()` (reutilise `getAllEntries`)

**Fichiers iOS a creer :**
- `ios/CaveAVin/Features/Cellar/CellarJournalView.swift` — vue timeline

**Fichiers iOS a modifier :**
- `ios/CaveAVin/Models/CellarModels.swift` — ajout `HistoryEvent`, `HistoryEventType`
- `ios/CaveAVin/API/CellarAPI.swift` — ajout `getHistory()`
- `ios/CaveAVin/Features/Cellar/CellarGridViewModel.swift` — ajout `history`, `displayMode`, chargement parallele
- `ios/CaveAVin/Features/Cellar/CellarGridView.swift` — ajout Picker segmented Cave/Journal

**Implementation backend :**

1. `getHistory()` dans `server/cellar/index.ts` :
   - Itere toutes les entrees (`getAllEntries`)
   - Pour chaque entree : cree un event "entry" (avec `dateIn`) et si `dateOut` existe, un event "exit"
   - Enrichit avec les infos vin (nom, couleur) via `Wines.getById`
   - Trie par date decroissante
   - Retourne `{ type, date, wineId, wineName, wineColor, position, rating?, tastingNotes? }[]`

**Implementation iOS :**

1. Models : `HistoryEvent { type: entry|exit, date, wineId, wineName, wineColor, position, rating?, tastingNotes? }`
2. `CellarGridViewModel` : ajout `displayMode` (enum `.cave` / `.journal`), `history: [HistoryEvent]`, chargement parallele grid + history avec `async let`
3. `CellarGridView` : `Picker` segmented en haut, switch entre liste groupee (Feature 1) et `CellarJournalView`
4. `CellarJournalView` : groupee par date, chaque event montre icone (fleche verte entree / rouge sortie), nom vin, badge couleur, position, rating si sortie notee

---

## Ordre d'implementation

1. **Feature 3** — Top vins (1 fichier, changement minimal)
2. **Feature 2** — PhotosPicker (1 fichier)
3. **Feature 1** — Redesign Cave en liste (3 fichiers iOS, pas de backend)
4. **Feature 4** — Dashboard (2 fichiers backend + 4 fichiers iOS)
5. **Feature 5** — Journal/Timeline (1 fichier backend + 4 fichiers iOS, depend de F1 et F4)

## Verification et review apres chaque feature

Apres chaque feature :
1. Build backend (si modifie) : `bun tsc --noEmit`
2. Build iOS : `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/CaveAVin.xcodeproj -scheme CaveAVin -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build`
3. **Code review SwiftUI** : invoquer le skill `swiftui-expert-skill` pour verifier state management, modern APIs, view composition, performance, concurrency
4. **Code review backend** (si modifie) : invoquer le skill `nitro-backend` pour verifier les patterns Nitro, branded types, Zod validation, storage
5. Corriger les problemes identifies par les reviews
6. Commit git apres validation
