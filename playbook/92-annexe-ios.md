# Annexe : pattern de feature iOS

Forme longue de [10-ios.md](10-ios.md). Feature d'exemple neutre : une liste d'objets, `Item`.

## Arborescence d'une feature

```
Features/{Feature}/
├── {Feature}View.swift        coordinateur : modèle de vue, navigation, feuilles, conversion
├── {Feature}Models.swift      structures de modèle
├── {Feature}API.swift         façade des opérations réseau
├── {Feature}ViewModel.swift   état observable
├── GraphQL/                   fichiers d'opérations
└── components/
    ├── pages/                 mises en page pures et prévisualisables
    ├── organisms/             sections composites, formulaires
    └── molecules/             lignes, badges, petits assemblages
```

Les atomes réutilisés entre features vivent dans le dossier partagé. Le projet synchronise les
fichiers depuis le système de fichiers : aucun ajout manuel dans le fichier de projet.

## Modèle de vue

Sur l'acteur principal, observable, état exposé en lecture seule. Tout appel réseau bascule un
indicateur de chargement, sans exception.

```swift
@MainActor @Observable
final class ItemListViewModel {
    private(set) var items: [Item] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do { items = try await ItemAPI.list().items }
        catch { errorMessage = reportError(error) }
    }
}
```

## Coordinateur

La vue racine de la feature possède le modèle de vue et tous les effets de bord : chargement,
navigation, présentation de feuilles. Elle convertit les modèles de domaine en primitives, et ne
porte aucune présentation.

```swift
struct ItemListView: View {
    @State private var viewModel = ItemListViewModel()

    var body: some View {
        NavigationStack {
            ItemListPage(
                rows: mappedRows,
                isLoading: viewModel.isLoading,
                errorMessage: viewModel.errorMessage,
                onTap: { selectedId = $0 },
                onRefresh: { await viewModel.load() }
            )
            .task { await viewModel.load() }
        }
    }
}
```

## Page

Sous `components/pages/`, la page ne reçoit que des liaisons, des primitives et des fermetures.
Pas de modèle de vue, pas d'appel réseau. Elle ajoute l'habillage de navigation et se prévisualise
sans serveur.

## Vues feuilles

Les atomes et molécules ne reçoivent que des primitives : chaînes, nombres, booléens, dates
optionnelles, énumérations simples sans logique, fermetures. Jamais une structure de domaine.

Au-delà de cinq paramètres, on passe par une structure de présentation dédiée à la feature plutôt
que d'allonger la signature.

Les organismes sont la frontière où la conversion domaine vers primitives a lieu.

## Previews

Chaque composant a sa preview, avec des données factices : c'est le catalogue de l'application.
Les previews qui dépendent d'une initialisation globale l'appellent explicitement, celles qui
dépendent d'un capteur absent du canevas rendent leur habillage au-dessus d'un fond vide.

## Boutons de barre

Un bouton synchrone pour une action immédiate, un bouton asynchrone qui affiche sa progression
pour une action qui part sur le réseau. Voir [10-ios.md](10-ios.md).

## Client d'API

Un singleton porte le transport et l'injection du jeton d'authentification. Chaque feature expose
une façade qui retourne les types de modèle de l'application, jamais les types générés bruts. Les
opérations vivent dans la feature, les types générés dans leur dossier dédié, qu'on ne modifie
jamais à la main.

Lecture sans cache, mutations sans publication dans un magasin local. La page d'ouverture d'une
liste gardée sur disque n'est pas un cache du client d'API : c'est un instantané de ce que l'écran
montrait, relu au lancement puis remplacé par la réponse du serveur. Voir
[10-ios.md](10-ios.md#chargements).

## Secrets

Les jetons vivent dans un fichier ignoré par git, avec un fichier d'exemple à côté qui documente
le format attendu. Le fichier équivalent des tests d'interface suit la même règle.
