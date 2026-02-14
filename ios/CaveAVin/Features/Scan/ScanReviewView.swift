import SwiftUI

struct ScanReviewView: View {
    let scanResult: ScanResult
    let imageData: Data
    let onSave: (CreateWineRequest) -> Void

    @State private var name: String
    @State private var color: WineColor
    @State private var domain: String
    @State private var vintage: String
    @State private var appellation: String
    @State private var region: String
    @State private var country: String
    @State private var grapeVarieties: String
    @State private var alcoholContent: String
    @State private var classification: String
    @State private var estimatedPrice: String
    @State private var drinkFrom: String
    @State private var drinkUntil: String

    init(scanResult: ScanResult, imageData: Data, onSave: @escaping (CreateWineRequest) -> Void) {
        self.scanResult = scanResult
        self.imageData = imageData
        self.onSave = onSave
        _name = State(initialValue: scanResult.name)
        _color = State(initialValue: scanResult.color)
        _domain = State(initialValue: scanResult.domain ?? "")
        _vintage = State(initialValue: scanResult.vintage.map(String.init) ?? "")
        _appellation = State(initialValue: scanResult.appellation ?? "")
        _region = State(initialValue: scanResult.region ?? "")
        _country = State(initialValue: scanResult.country ?? "")
        _grapeVarieties = State(initialValue: scanResult.grapeVarieties.joined(separator: ", "))
        _alcoholContent = State(initialValue: scanResult.alcoholContent.map { String(format: "%.1f", $0) } ?? "")
        _classification = State(initialValue: scanResult.classification ?? "")
        _estimatedPrice = State(initialValue: scanResult.estimatedPrice.map { String(format: "%.0f", $0) } ?? "")
        _drinkFrom = State(initialValue: scanResult.drinkFrom.map(String.init) ?? "")
        _drinkUntil = State(initialValue: scanResult.drinkUntil.map(String.init) ?? "")
    }

    var body: some View {
        Form {
            if let uiImage = UIImage(data: imageData) {
                Section {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Section("Informations principales") {
                TextField("Nom", text: $name)
                Picker("Couleur", selection: $color) {
                    ForEach(WineColor.allCases) { c in
                        Text(c.label).tag(c)
                    }
                }
                TextField("Domaine", text: $domain)
                TextField("Millésime", text: $vintage)
                    .keyboardType(.numberPad)
            }

            Section("Origine") {
                TextField("Appellation", text: $appellation)
                TextField("Région", text: $region)
                TextField("Pays", text: $country)
                TextField("Classification", text: $classification)
            }

            Section("Détails") {
                TextField("Cépages (séparés par des virgules)", text: $grapeVarieties)
                TextField("Degré d'alcool", text: $alcoholContent)
                    .keyboardType(.decimalPad)
                TextField("Prix estimé (€)", text: $estimatedPrice)
                    .keyboardType(.decimalPad)
            }

            Section("Garde") {
                TextField("À boire à partir de", text: $drinkFrom)
                    .keyboardType(.numberPad)
                TextField("À boire jusqu'à", text: $drinkUntil)
                    .keyboardType(.numberPad)
            }

            Section {
                Button("Ajouter à la cave") {
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
                        alcoholContent: Double(alcoholContent),
                        classification: classification.isEmpty ? nil : classification,
                        purchasePrice: Double(estimatedPrice),
                        drinkFrom: Int(drinkFrom),
                        drinkUntil: Int(drinkUntil),
                        imageBase64: imageData.base64EncodedString()
                    )
                    onSave(request)
                }
                .frame(maxWidth: .infinity)
                .disabled(name.isEmpty)
            }
        }
        .navigationTitle("Vérifier le vin")
    }
}
