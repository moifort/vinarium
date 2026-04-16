import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var pending: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCurrentCoordinate() async -> CLLocationCoordinate2D? {
        let status = manager.authorizationStatus
        if status == .denied || status == .restricted { return nil }

        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
            let granted = await waitForAuthorizationDecision()
            if !granted { return nil }
        }

        return await withCheckedContinuation { continuation in
            if pending != nil {
                continuation.resume(returning: nil)
                return
            }
            pending = continuation
            manager.requestLocation()
        }
    }

    private var authorizationContinuation: CheckedContinuation<Bool, Never>?

    private func waitForAuthorizationDecision() async -> Bool {
        await withCheckedContinuation { continuation in
            if authorizationContinuation != nil {
                continuation.resume(returning: false)
                return
            }
            authorizationContinuation = continuation
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        Task { @MainActor in
            guard let continuation = self.authorizationContinuation else { return }
            self.authorizationContinuation = nil
            continuation.resume(returning: status == .authorizedWhenInUse || status == .authorizedAlways)
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        let coordinate = locations.last?.coordinate
        Task { @MainActor in
            guard let continuation = self.pending else { return }
            self.pending = nil
            continuation.resume(returning: coordinate)
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            guard let continuation = self.pending else { return }
            self.pending = nil
            continuation.resume(returning: nil)
        }
    }
}
