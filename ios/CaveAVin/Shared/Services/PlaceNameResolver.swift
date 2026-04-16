import CoreLocation

@MainActor
enum PlaceNameResolver {
    private static let geocoder = CLGeocoder()

    static func resolve(_ coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }
            return format(placemark)
        } catch {
            return nil
        }
    }

    private static func format(_ placemark: CLPlacemark) -> String? {
        let primary = placemark.locality ?? placemark.subLocality ?? placemark.administrativeArea
        let country = placemark.country
        switch (primary, country) {
        case let (primary?, country?): return "\(primary), \(country)"
        case let (primary?, nil): return primary
        case let (nil, country?): return country
        default: return nil
        }
    }
}
