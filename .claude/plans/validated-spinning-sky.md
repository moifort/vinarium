# Plan: Supprimer Stats + Creer Skill Dev Workflow

## Contexte

L'utilisateur souhaite :
1. Supprimer la page Stats (front iOS + back) car elle n'est plus necessaire
2. Creer un nouveau skill decrivant le cycle de developpement d'une feature, base sur le workflow utilise dans ce projet, packagé comme un repo GitHub installable via `bunx skills add`

---

## Tache 1 : Supprimer la page Stats

Le module Finance/Stats est completement autonome - aucun autre domaine n'en depend.

### Fichiers a supprimer

**iOS (4 fichiers) :**
- `ios/CaveAVin/Features/Stats/StatsView.swift`
- `ios/CaveAVin/Features/Stats/StatsViewModel.swift`
- `ios/CaveAVin/API/FinanceAPI.swift`
- `ios/CaveAVin/Models/FinanceModels.swift`

**Backend (4 fichiers/dossiers) :**
- `server/finance/index.ts`
- `server/finance/types.ts`
- `server/routes/finances/summary.get.ts` (+ dossier `server/routes/finances/`)
- `server/tasks/finance/snapshot.ts` (+ dossier `server/tasks/finance/`)

**Donnees :**
- `.data/db/finance/` - Supprimer le dossier de donnees

### Fichiers a modifier

**`ios/CaveAVin/ContentView.swift`** - Supprimer le tab Stats (lignes 19-21) :
```swift
// Supprimer :
Tab("Stats", systemImage: "chart.bar") {
    StatsView()
}
```

**`nitro.config.ts`** - Supprimer la config finance :
- Ligne 10 : `finance: { driver: 'fs', base: './.data/db/finance' },`
- Ligne 14 : `'0 0 1 * *': ['finance:snapshot'],`
- Supprimer `scheduledTasks` et `experimental: { tasks: true }` si plus aucune tache restante

---

## Tache 2 : Creer le Skill "Feature Development Workflow"

### Structure du repo

Creer dans `/Users/thibaut/Code/feature-dev-workflow/` :

```
feature-dev-workflow/
├── .claude-plugin/
│   └── plugin.json          # Metadata pour bunx skills add
├── skills/
│   └── feature-dev-workflow/
│       └── SKILL.md          # Le skill principal
├── .gitignore
└── README.md                 # (optionnel, si demande)
```

### Contenu de `.claude-plugin/plugin.json`

```json
{
  "name": "feature-dev-workflow",
  "version": "1.0.0",
  "description": "Feature development workflow skill: plan, validate, implement, verify, commit",
  "author": {
    "name": "moifort"
  }
}
```

### Contenu du Skill (SKILL.md)

Le skill sera generique (pas specifique a un stack) et decrira le cycle complet en 4 phases :

```yaml
---
name: feature-dev-workflow
description: Use when developing a new feature, fixing a bug, or making significant code changes - guides the full cycle from planning through verified commit with expert review
---
```

**Phase 1 - Planification :**
- Identifier et invoquer les skills adaptes au stack du projet (lister les skills disponibles)
- Invoquer `superpowers:brainstorming` si le scope est ambigu
- Poser des questions a l'utilisateur pour clarifier les besoins (AskUserQuestion)
- Utiliser `EnterPlanMode` pour rediger un plan detaille
- Le plan doit inclure : contexte, fichiers a modifier, etapes d'implementation, verification

**Phase 2 - Validation :**
- Presenter le plan a l'utilisateur via `ExitPlanMode`
- Ne jamais commencer l'implementation sans approbation explicite
- Integrer les retours de l'utilisateur si necessaire

**Phase 3 - Implementation :**
- Suivre le plan valide etape par etape
- Invoquer les skills techniques pertinents pour chaque partie
- Utiliser `TaskCreate`/`TaskUpdate` pour tracker la progression
- Decouper en commits logiques (1 feature = 1 commit)

**Phase 4 - Verification & Commit :**
- Code review par agents experts (`superpowers:requesting-code-review`)
- Compiler/type-checker le projet (commandes definies dans CLAUDE.md ou le projet)
- Conventional commit obligatoire : `<type>(<scope>): <description>`
  - `type` : feat, fix, chore, refactor, docs, test
  - `scope` : nom de la feature/module entre parentheses
  - Exemples : `feat(auth): add login page`, `fix(cellar): fix grid layout`
- Footer `Co-Authored-By` si assiste par IA
- Flowchart du cycle inclus dans le skill pour guider la decision

### Installation

```bash
bunx skills add https://github.com/moifort/feature-dev-workflow --skill feature-dev-workflow
```

---

## Verification

### Tache 1 (Stats)
1. `bun tsc --noEmit` - verification types backend
2. `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/CaveAVin.xcodeproj -scheme CaveAVin -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build` - compilation iOS
3. Verifier que l'app compile sans reference a Stats/Finance

### Tache 2 (Skill)
1. Verifier la structure du repo
2. `cd /Users/thibaut/Code/feature-dev-workflow && git init && git add -A && git commit -m "feat: initial feature-dev-workflow skill"`

### Commits
- Commit 1 : `chore(stats): remove stats page and finance backend`
- Commit 2 : Le skill est dans un repo separe, commit independant
