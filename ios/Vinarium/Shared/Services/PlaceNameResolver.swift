import CoreLocation
@preconcurrency import MapKit

@MainActor
enum PlaceNameResolver {
    static func resolve(_ coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        do {
            let mapItems = try await request.mapItems
            guard let item = mapItems.first else { return nil }
            return item.addressRepresentations?.cityWithContext
                ?? item.address?.shortAddress
                ?? item.address?.fullAddress
        } catch {
            return nil
        }
    }
}
