import MapKit
import SwiftUI

/// Where the wine was tasted, as a map with rounded corners and, floating over its
/// foot on glass, the place's name and "Ajuster". The whole map opens the editor.
/// Without a place, a single row offers to add one.
struct WineLocationMap: View {
    let placeName: String?
    let latitude: Double?
    let longitude: Double?
    let onTap: () -> Void

    var body: some View {
        if let latitude, let longitude {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            Button(action: onTap) {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))) {
                    Marker("", coordinate: coordinate)
                }
                .allowsHitTesting(false)
                .frame(height: 170)
                .overlay(alignment: .bottom) {
                    HStack {
                        Text(displayName(coordinate))
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                            .capsuleOnGlass()
                        Spacer(minLength: 8)
                        Text("Ajuster")
                            .foregroundStyle(.tint)
                            .capsuleOnGlass()
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(10)
                }
                .clipShape(.rect(cornerRadius: 22))
                .contentShape(.rect(cornerRadius: 22))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("wine-detail-location")
        } else {
            Button(action: onTap) {
                Label("Ajouter un lieu", systemImage: "mappin.and.ellipse")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.tint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .overlay(alignment: .top) {
                        Rectangle().fill(Color(.separator)).frame(height: 0.5)
                    }
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("wine-detail-add-location")
        }
    }

    private func displayName(_ coordinate: CLLocationCoordinate2D) -> String {
        if let placeName, !placeName.isEmpty { return placeName }
        return String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }
}

private extension View {
    func capsuleOnGlass() -> some View {
        padding(.horizontal, 13)
            .frame(height: 34)
            .glassEffect(.regular, in: .capsule)
    }
}

#Preview("Place") {
    WineLocationMap(placeName: "Margaux, France", latitude: 45.0436, longitude: -0.6731, onTap: {})
        .padding(20)
}

#Preview("No place") {
    WineLocationMap(placeName: nil, latitude: nil, longitude: nil, onTap: {})
        .padding(20)
}
