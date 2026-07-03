import SwiftUI

struct ScanReviewPage: View {
    let scanResult: ScanResult
    let imageData: Data
    let destination: ScanDestination
    let onSave: (CreateWineRequest) async -> Void
    let onFavorite: (CreateWineRequest, Date, [String], String?) async -> Void
    let onShortlist: (CreateWineRequest, Date, Int?, [String], String?) async -> Void
    let onRecommend: (CreateWineRequest, String?, String?) async -> Void
    /// Reçoit l'état édité du formulaire pour que le retour à l'écran destination ne perde rien.
    let onChangeDestination: (ScanResult) -> Void
    let onCancel: () -> Void

    @State private var showLocationEditor = false
    @State private var name: String
    @State private var beverageType: BeverageType
    @State private var color: WineColor
    @State private var style: String
    @State private var alcoholContent: String
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
    @State private var location: DiscoveryLocationDraft?

    // Champs de la destination (dégustation / conseil), saisis inline
    @State private var tastingDate = Date()
    @State private var contacts: [String] = []
    @State private var tastingNotes = ""
    @State private var rating = 3
    @State private var recommenderName = ""
    @State private var recommendationComment = ""
    @State private var showContactPicker = false
    @State private var showRecommenderPicker = false

    init(
        scanResult: ScanResult,
        imageData: Data,
        destination: ScanDestination,
        initialLocation: DiscoveryLocationDraft? = nil,
        onSave: @escaping (CreateWineRequest) async -> Void,
        onFavorite: @escaping (CreateWineRequest, Date, [String], String?) async -> Void = { _, _, _, _ in },
        onShortlist: @escaping (CreateWineRequest, Date, Int?, [String], String?) async -> Void = { _, _, _, _, _ in },
        onRecommend: @escaping (CreateWineRequest, String?, String?) async -> Void = { _, _, _ in },
        onChangeDestination: @escaping (ScanResult) -> Void = { _ in },
        onCancel: @escaping () -> Void = {}
    ) {
        self.scanResult = scanResult
        self.imageData = imageData
        self.destination = destination
        self.onSave = onSave
        self.onFavorite = onFavorite
        self.onShortlist = onShortlist
        self.onRecommend = onRecommend
        self.onChangeDestination = onChangeDestination
        self.onCancel = onCancel
        _name = State(initialValue: scanResult.name)
        _beverageType = State(initialValue: scanResult.beverageType)
        _color = State(initialValue: scanResult.color ?? .red)
        _style = State(initialValue: scanResult.style ?? "")
        _alcoholContent = State(initialValue: scanResult.alcoholContent.map { String(format: "%.1f", $0) } ?? "")
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
        _location = State(initialValue: initialLocation)
    }

    private var isWine: Bool { beverageType == .wine }

    var body: some View {
        Form {
            destinationSection
            photoSection
            mainInfoSection
            if isWine { originSection }
            destinationDetailsSection
            locationSection
            detailsSection
            if isWine { gardeSection }
            giftedBySection
        }
        .navigationTitle("Vérifier la bouteille")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fermer", systemImage: "xmark") { onCancel() }
            }

            ToolbarItemGroup(placement: .primaryAction) {
                AsyncToolbarButton(title: destination.ctaTitle, systemImage: "plus") {
                    await submit()
                }
                .accessibilityIdentifier("review-save-button")
            }
        }
        .sheet(isPresented: $showGiftedByPicker) {
            ContactPicker { name in
                giftedBy = name
            }
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPicker { name in
                if !contacts.contains(name) {
                    contacts.append(name)
                }
            }
        }
        .sheet(isPresented: $showRecommenderPicker) {
            ContactPicker { name in
                recommenderName = name
            }
        }
        .sheet(isPresented: $showLocationEditor) {
            LocationEditorSheet(initial: location) { draft in
                location = draft
                showLocationEditor = false
            }
        }
    }

    // MARK: - Sections

    private var destinationSection: some View {
        Section {
            HStack {
                Label {
                    Text(destination.label)
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: destination.icon)
                        .foregroundStyle(.tint)
                }
                Spacer()
                Button("Modifier") { onChangeDestination(editedScanResult()) }
                    .font(.subheadline)
                    .accessibilityIdentifier("review-change-destination-button")
            }
        } header: {
            Text("Destination")
        }
    }

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
                TextField("Nom", text: $name)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("review-name-field")
            } label: {
                Label("Nom", systemImage: "wineglass")
            }

            Picker(selection: $beverageType) {
                ForEach(BeverageType.allCases) { type in
                    Text(type.label).tag(type)
                }
            } label: {
                Label("Type", systemImage: "square.grid.2x2")
            }
            .accessibilityIdentifier("review-beverage-type-picker")

            if isWine {
                Picker(selection: $color) {
                    ForEach(WineColor.allCases) { c in
                        Text(c.label).tag(c)
                    }
                } label: {
                    Label("Couleur", systemImage: "paintpalette")
                }
            } else {
                LabeledContent {
                    TextField("IPA, Single Malt, Junmai...", text: $style)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Style", systemImage: "tag")
                }
            }

            LabeledContent {
                TextField(beverageType.producerLabel, text: $domain)
                    .multilineTextAlignment(.trailing)
            } label: {
                Label(beverageType.producerLabel, systemImage: "building.2")
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

    @ViewBuilder
    private var destinationDetailsSection: some View {
        switch destination {
        case .cellar:
            EmptyView()

        case .favorite:
            Section {
                tastingDateRow
                contactsRows
                tastingNotesField
            } header: {
                Text("Dégustation")
            }

        case .shortlist:
            Section {
                tastingDateRow
                Picker(selection: $rating) {
                    ForEach(1...4, id: \.self) { value in
                        Text("\(value) / 5").tag(value)
                    }
                } label: {
                    Label("Note", systemImage: "star")
                }
                .accessibilityIdentifier("shortlist-rating-picker")
                contactsRows
                tastingNotesField
            } header: {
                Text("Dégustation")
            }

        case .recommendation:
            Section {
                HStack {
                    Label("Conseillé par", systemImage: "person.badge.star")
                    TextField("Nom", text: $recommenderName)
                        .textInputAutocapitalization(.words)
                        .multilineTextAlignment(.trailing)
                        .accessibilityIdentifier("review-recommender-field")
                    Button {
                        showRecommenderPicker = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Label("Commentaires", systemImage: "text.quote")
                        .foregroundStyle(.secondary)
                    TextField("Pourquoi ce conseil ?", text: $recommendationComment, axis: .vertical)
                        .lineLimit(3...6)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Conseil")
            }
        }
    }

    private var tastingDateRow: some View {
        HStack {
            Label("Date", systemImage: "calendar")
            Spacer()
            DatePicker("", selection: $tastingDate, in: ...Date(), displayedComponents: .date)
                .labelsHidden()
        }
    }

    @ViewBuilder
    private var contactsRows: some View {
        HStack {
            Label("Avec", systemImage: "person.2")
            Spacer()
            Button {
                showContactPicker = true
            } label: {
                Label("Ajouter", systemImage: "plus.circle")
                    .font(.subheadline)
            }
        }
        ForEach(contacts, id: \.self) { contact in
            HStack {
                Text(contact)
                Spacer()
                Button {
                    contacts.removeAll { $0 == contact }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var tastingNotesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Commentaires", systemImage: "text.quote")
                .foregroundStyle(.secondary)
            TextField("Vos impressions, arômes, accords...", text: $tastingNotes, axis: .vertical)
                .lineLimit(3...6)
        }
        .padding(.vertical, 4)
    }

    private var locationSection: some View {
        LocationSection(
            placeName: location?.placeName,
            latitude: location?.latitude,
            longitude: location?.longitude,
            onTap: { showLocationEditor = true }
        )
    }

    private var detailsSection: some View {
        Section {
            if isWine {
                LabeledContent {
                    TextField("Cépages", text: $grapeVarieties)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Cépages", systemImage: "leaf")
                }
            }

            LabeledContent {
                HStack(spacing: 4) {
                    TextField("0", text: $alcoholContent)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("% vol")
                        .foregroundStyle(.secondary)
                }
            } label: {
                Label("Degré", systemImage: "percent")
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

    private func submit() async {
        var request = buildRequest()
        switch destination {
        case .cellar:
            await onSave(request)
        case .favorite:
            request.rating = 5
            await onFavorite(request, tastingDate, contacts, tastingNotes.isEmpty ? nil : tastingNotes)
        case .shortlist:
            request.shortlist = true
            request.rating = rating
            await onShortlist(request, tastingDate, rating, contacts, tastingNotes.isEmpty ? nil : tastingNotes)
        case .recommendation:
            await onRecommend(
                request,
                recommenderName.isEmpty ? nil : recommenderName,
                recommendationComment.isEmpty ? nil : recommendationComment
            )
        }
    }

    /// L'état courant du formulaire re-projeté en ScanResult, pour ré-ouvrir la review
    /// avec les mêmes valeurs après un aller-retour par l'écran destination.
    private func editedScanResult() -> ScanResult {
        ScanResult(
            name: name,
            beverageType: beverageType,
            domain: domain.isEmpty ? nil : domain,
            vintage: Int(vintage),
            appellation: appellation.isEmpty ? nil : appellation,
            region: region.isEmpty ? nil : region,
            country: country.isEmpty ? nil : country,
            color: isWine ? color : nil,
            style: style.isEmpty ? nil : style,
            grapeVarieties: grapeVarieties
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty },
            alcoholContent: Double(alcoholContent.replacingOccurrences(of: ",", with: ".")),
            classification: classification.isEmpty ? nil : classification,
            drinkFrom: Int(drinkFrom),
            drinkUntil: Int(drinkUntil),
            estimatedPrice: Double(estimatedPrice)
        )
    }

    private func buildRequest() -> CreateWineRequest {
        let varieties = grapeVarieties
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return CreateWineRequest(
            name: name,
            beverageType: beverageType,
            color: isWine ? color : nil,
            style: isWine || style.isEmpty ? nil : style,
            domain: domain.isEmpty ? nil : domain,
            vintage: Int(vintage),
            appellation: isWine && !appellation.isEmpty ? appellation : nil,
            region: region.isEmpty ? nil : region,
            country: country.isEmpty ? nil : country,
            grapeVarieties: isWine && !varieties.isEmpty ? varieties : nil,
            alcoholContent: Double(alcoholContent.replacingOccurrences(of: ",", with: ".")),
            classification: isWine && !classification.isEmpty ? classification : nil,
            purchasePrice: Double(estimatedPrice),
            drinkFrom: isWine ? Int(drinkFrom) : nil,
            drinkUntil: isWine ? Int(drinkUntil) : nil,
            giftedBy: giftedBy.isEmpty ? nil : giftedBy,
            latitude: location?.latitude,
            longitude: location?.longitude,
            placeName: location?.placeName
        )
    }
}
// MARK: - Preview

private let mockImageData: Data = {
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

#Preview("Vin vers la cave") {
    let mockScanResult = ScanResult(
        name: "Château Margaux",
        beverageType: .wine,
        domain: "Château Margaux",
        vintage: 2018,
        appellation: "Margaux",
        region: "Bordeaux",
        country: "France",
        color: .red,
        style: nil,
        grapeVarieties: ["Cabernet Sauvignon", "Merlot", "Petit Verdot"],
        alcoholContent: 13.5,
        classification: "1er Grand Cru Classé",
        drinkFrom: 2025,
        drinkUntil: 2045,
        estimatedPrice: 650
    )

    NavigationStack {
        ScanReviewPage(
            scanResult: mockScanResult,
            imageData: mockImageData,
            destination: .cellar,
            onSave: { _ in }
        )
    }
}

#Preview("Bière en favori") {
    let mockScanResult = ScanResult(
        name: "La Chouffe",
        beverageType: .beer,
        domain: "Brasserie d'Achouffe",
        vintage: nil,
        appellation: nil,
        region: "Wallonie",
        country: "Belgique",
        color: nil,
        style: "Blonde forte",
        grapeVarieties: [],
        alcoholContent: 8,
        classification: nil,
        drinkFrom: nil,
        drinkUntil: nil,
        estimatedPrice: 3
    )

    NavigationStack {
        ScanReviewPage(
            scanResult: mockScanResult,
            imageData: mockImageData,
            destination: .favorite,
            onSave: { _ in }
        )
    }
}
