import SwiftUI

struct ScanReviewView: View {
    let scanResult: ScanResult
    let imageData: Data
    let isSaving: Bool
    let onSave: (CreateWineRequest) -> Void

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

    init(scanResult: ScanResult, imageData: Data, isSaving: Bool = false, onSave: @escaping (CreateWineRequest) -> Void) {
        self.scanResult = scanResult
        self.imageData = imageData
        self.isSaving = isSaving
        self.onSave = onSave
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
            saveSection
        }
        .navigationTitle("Vérifier le vin")
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
            Label("Informations principales", systemImage: "info.circle")
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
            Label("Origine", systemImage: "mappin.and.ellipse")
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
                    Text("€")
                        .foregroundStyle(.secondary)
                }
            } label: {
                Label("Prix", systemImage: "eurosign.circle")
            }
        } header: {
            Label("Détails", systemImage: "list.bullet.rectangle")
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
            Label("Garde", systemImage: "clock.arrow.2.circlepath")
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                save()
            } label: {
                Label("Ajouter à la cave", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
            }
            .disabled(name.isEmpty || isSaving)
        }
    }

    // MARK: - Actions

    private func save() {
        let varieties = grapeVarieties
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let request = CreateWineRequest(
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
            imageBase64: imageData.base64EncodedString()
        )
        onSave(request)
    }
}
