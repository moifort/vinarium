import SwiftUI

struct WineOriginSection: View {
    let appellation: String?
    let region: String?
    let country: String?
    let classification: String?

    var body: some View {
        if appellation != nil || region != nil || country != nil || classification != nil {
            Section("Origine") {
                if let appellation {
                    LabeledInfoRow(title: "Appellation", value: appellation, icon: "seal")
                }
                if let region {
                    LabeledInfoRow(title: "R\u{00E9}gion", value: region, icon: "map")
                }
                if let country {
                    LabeledInfoRow(title: "Pays", value: country, icon: "globe.europe.africa")
                }
                if let classification {
                    LabeledInfoRow(title: "Classification", value: classification, icon: "rosette")
                }
            }
        }
    }
}

#Preview {
    List {
        WineOriginSection(
            appellation: "Margaux",
            region: "Bordeaux",
            country: "France",
            classification: "Premier Grand Cru Class\u{00E9}"
        )
    }
}
