import SwiftUI

struct ScanReviewView: View {
    let scanResult: ScanResult
    let imageData: Data
    let isSaving: Bool
    let onSave: (CreateWineRequest) -> Void
    let onFavorite: (CreateWineRequest, Date, [String], String?) -> Void
    let onRecommend: (CreateWineRequest, String?, String?) -> Void
    let onCancel: () -> Void

    @State private var showFavorite = false
    @State private var showRecommendation = false
    @State private var name: String
    @State private var color: WineColor
    @State private var domain: String
    @State private var vintage: String
    @State private var appellation: String
    @State private var region: String
    @State private var country: String
    @State private var grapeVarieties: String
    @State private var classification: String
    @State private var estimatedPrice: String
    @State private var drinkFrom: String
    @State private var drinkUntil: String
    @State private var giftedBy = ""
    @State private var showGiftedByPicker = false

    init(scanResult: ScanResult, imageData: Data, isSaving: Bool = false, onSave: @escaping (CreateWineRequest) -> Void, onFavorite: @escaping (CreateWineRequest, Date, [String], String?) -> Void = { _, _, _, _ in }, onRecommend: @escaping (CreateWineRequest, String?, String?) -> Void = { _, _, _ in }, onCancel: @escaping () -> Void = {}) {
        self.scanResult = scanResult
        self.imageData = imageData
        self.isSaving = isSaving
        self.onSave = onSave
        self.onFavorite = onFavorite
        self.onRecommend = onRecommend
        self.onCancel = onCancel
        _name = State(initialValue: scanResult.name)
        _color = State(initialValue: scanResult.color)
        _domain = State(initialValue: scanResult.domain ?? "")
        _vintage = State(initialValue: scanResult.vintage.map(String.init) ?? "")
        _appellation = State(initialValue: scanResult.appellation ?? "")
        _region = State(initialValue: scanResult.region ?? "")
        _country = State(initialValue: scanResult.country ?? "")
        _grapeVarieties = State(initialValue: scanResult.grapeVarieties.joined(separator: ", "))
        _classification = State(initialValue: scanResult.classification ?? "")
        _estimatedPrice = State(initialValue: scanResult.estimatedPrice.map { String(format: "%.0f", $0) } ?? "")
        _drinkFrom = State(initialValue: scanResult.drinkFrom.map(String.init) ?? "")
        _drinkUntil = State(initialValue: scanResult.drinkUntil.map(String.init) ?? "")
    }

    var body: some View {
        Form {
            photoSection
            mainInfoSection
            originSection
            detailsSection
            gardeSection
            giftedBySection
        }
        .navigationTitle("Vérifier le vin")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fermer", systemImage: "xmark") { onCancel() }
            }

            ToolbarItemGroup {
                    Button {
                        showFavorite = true
                    } label: {
                        Label("Ajouter aux favoris", systemImage: "heart")
                    }
                    .accessibilityIdentifier("review-favorite-button")

                    Button {
                        showRecommendation = true
                    } label: {
                        Label("Conseillé par un ami", systemImage: "person.badge.plus")
                    }
                    .accessibilityIdentifier("review-recommend-button")

            }
            ToolbarSpacer(.fixed)

            ToolbarItemGroup(placement: .primaryAction) {
                Button("Ajouter à la cave", systemImage: "plus") {
                    save()
                }
                .accessibilityIdentifier("review-save-button")
            }
        }
        .sheet(isPresented: $showGiftedByPicker) {
            ContactPicker { name in
                giftedBy = name
            }
        }
        .sheet(isPresented: $showFavorite) {
            FavoriteSheet { date, contacts, notes in
                showFavorite = false
                var request = buildRequest()
                request.rating = 5
                onFavorite(request, date, contacts, notes)
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showRecommendation) {
            RecommendationSheet { recommenderName, comment in
                showRecommendation = false
                onRecommend(buildRequest(), recommenderName, comment)
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var photoSection: some View {
        if let uiImage = UIImage(data: imageData) {
            Section {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
    }

    private var mainInfoSection: some View {
        Section {
            LabeledContent {
                TextField("Nom du vin", text: $name)
                    .multilineTextAlignment(.trailing)
            } label: {
                Label("Nom", systemImage: "wineglass")
            }

            Picker(selection: $color) {
                ForEach(WineColor.allCases) { c in
                    Text(c.label).tag(c)
                }
            } label: {
                Label("Couleur", systemImage: "paintpalette")
            }

            LabeledContent {
                TextField("Domaine", text: $domain)
                    .multilineTextAlignment(.trailing)
            } label: {
                Label("Domaine", systemImage: "building.2")
            }

            LabeledContent {
                TextField("Année", text: $vintage)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            } label: {
                Label("Millésime", systemImage: "calendar")
            }
        } header: {
            Text("Informations principales")
        }
    }

    private var originSection: some View {
        Section {
            LabeledContent {
                TextField("Appellation", text: $appellation)
                    .multilineTextAlignment(.trailing)
            } label: {
                Label("Appellation", systemImage: "seal")
            }

            LabeledContent {
                TextField("Région", text: $region)
                    .multilineTextAlignment(.trailing)
            } label: {
                Label("Région", systemImage: "map")
            }

            LabeledContent {
                TextField("Pays", text: $country)
                    .multilineTextAlignment(.trailing)
            } label: {
                Label("Pays", systemImage: "globe.europe.africa")
            }

            LabeledContent {
                TextField("Classification", text: $classification)
                    .multilineTextAlignment(.trailing)
            } label: {
                Label("Classification", systemImage: "rosette")
            }
        } header: {
            Text("Origine")
        }
    }

    private var detailsSection: some View {
        Section {
            LabeledContent {
                TextField("Cépages", text: $grapeVarieties)
                    .multilineTextAlignment(.trailing)
            } label: {
                Label("Cépages", systemImage: "leaf")
            }

            LabeledContent {
                HStack(spacing: 4) {
                    TextField("0", text: $estimatedPrice)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .accessibilityIdentifier("review-price-field")
                    Text("€")
                        .foregroundStyle(.secondary)
                }
            } label: {
                Label("Prix", systemImage: "eurosign.circle")
            }
        } header: {
            Text("Détails")
        }
    }

    private var gardeSection: some View {
        Section {
            LabeledContent {
                TextField("Année", text: $drinkFrom)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            } label: {
                Label("À partir de", systemImage: "hourglass.bottomhalf.filled")
            }

            LabeledContent {
                TextField("Année", text: $drinkUntil)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            } label: {
                Label("Jusqu'à", systemImage: "hourglass.tophalf.filled")
            }
        } header: {
            Text("Garde")
        }
    }

    private var giftedBySection: some View {
        Section {
            HStack {
                Label("Offert par", systemImage: "gift")
                TextField("Nom", text: $giftedBy)
                    .textInputAutocapitalization(.words)
                    .multilineTextAlignment(.trailing)
                Button {
                    showGiftedByPicker = true
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Cadeau")
        }
    }

    // MARK: - Actions

    private func save() {
        onSave(buildRequest())
    }

    private func buildRequest() -> CreateWineRequest {
        let varieties = grapeVarieties
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return CreateWineRequest(
            name: name,
            color: color,
            domain: domain.isEmpty ? nil : domain,
            vintage: Int(vintage),
            appellation: appellation.isEmpty ? nil : appellation,
            region: region.isEmpty ? nil : region,
            country: country.isEmpty ? nil : country,
            grapeVarieties: varieties.isEmpty ? nil : varieties,
            classification: classification.isEmpty ? nil : classification,
            purchasePrice: Double(estimatedPrice),
            drinkFrom: Int(drinkFrom),
            drinkUntil: Int(drinkUntil),
            imageBase64: imageData.base64EncodedString(),
            giftedBy: giftedBy.isEmpty ? nil : giftedBy
        )
    }
}
// MARK: - Preview

#Preview("Scan Review") {
    let mockScanResult = ScanResult(
        name: "Château Margaux",
        domain: "Château Margaux",
        vintage: 2018,
        appellation: "Margaux",
        region: "Bordeaux",
        country: "France",
        color: .red,
        grapeVarieties: ["Cabernet Sauvignon", "Merlot", "Petit Verdot"],
        alcoholContent: 13.5,
        classification: "1er Grand Cru Classé",
        drinkFrom: 2025,
        drinkUntil: 2045,
        estimatedPrice: 650
    )

    // Petite image de placeholder en dégradé rouge/bordeaux
    let mockImageData: Data = {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 300))
        let image = renderer.image { ctx in
            let colors = [UIColor(red: 0.5, green: 0.05, blue: 0.1, alpha: 1).cgColor,
                          UIColor(red: 0.3, green: 0.02, blue: 0.05, alpha: 1).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: colors as CFArray,
                                      locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(gradient,
                                            start: .zero,
                                            end: CGPoint(x: 0, y: 300),
                                            options: [])
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }()

    NavigationStack {
        ScanReviewView(
            scanResult: mockScanResult,
            imageData: mockImageData,
            onSave: { _ in },
            onFavorite: { _, _, _, _ in },
            onRecommend: { _, _, _ in },
            onCancel: {}
        )
    }
}

#Preview("Saving in progress") {
    let mockScanResult = ScanResult(
        name: "Pouilly-Fumé",
        domain: "Domaine Didier Dagueneau",
        vintage: 2021,
        appellation: "Pouilly-Fumé",
        region: "Loire",
        country: "France",
        color: .white,
        grapeVarieties: ["Sauvignon Blanc"],
        alcoholContent: 12.5,
        classification: nil,
        drinkFrom: 2022,
        drinkUntil: 2028,
        estimatedPrice: 45
    )

    NavigationStack {
        ScanReviewView(
            scanResult: mockScanResult,
            imageData: Data(),
            isSaving: true,
            onSave: { _ in },
            onFavorite: { _, _, _, _ in },
            onRecommend: { _, _, _ in },
            onCancel: {}
        )
    }
}

