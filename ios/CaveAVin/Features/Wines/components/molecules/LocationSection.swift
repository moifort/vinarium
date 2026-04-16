import MapKit
import SwiftUI

struct LocationSection: View {
    let placeName: String?
    let latitude: Double?
    let longitude: Double?
    let onTap: () -> Void

    private var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var body: some View {
        Section("Lieu de d\u{00E9}couverte") {
            Button(action: onTap) {
                if let coordinate {
                    LocationPreview(coordinate: coordinate, placeName: placeName)
                } else {
                    Label("Ajouter un lieu", systemImage: "mappin.and.ellipse")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

private struct LocationPreview: View {
    let coordinate: CLLocationCoordinate2D
    let placeName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(placeName ?? coordinatesLabel, systemImage: "mappin.and.ellipse")
                .foregroundStyle(.primary)
            Map(initialPosition: .region(region)) {
                Marker("", coordinate: coordinate)
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .allowsHitTesting(false)
        }
        .padding(.vertical, 4)
    }

    private var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }

    private var coordinatesLabel: String {
        String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }
}

#Preview("With place name") {
    List {
        LocationSection(
            placeName: "Bordeaux, France",
            latitude: 44.84,
            longitude: -0.58,
            onTap: {}
        )
    }
}

#Preview("Coordinates only") {
    List {
        LocationSection(
            placeName: nil,
            latitude: 44.84,
            longitude: -0.58,
            onTap: {}
        )
    }
}

#Preview("Empty") {
    List {
        LocationSection(placeName: nil, latitude: nil, longitude: nil, onTap: {})
    }
}
