import CoreLocation
import Foundation

@MainActor
final class LocationProvider: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var location: CLLocation?
    @Published private(set) var errorMessage: String?

    private let manager: CLLocationManager
    private var isRequestingLocation = false
    private var timeoutTask: Task<Void, Never>?

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        guard isAuthorized, !isRequestingLocation else { return }

        isRequestingLocation = true
        errorMessage = nil
        manager.startUpdatingLocation()

        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled, let self else { return }
            self.finishRequest(with: Location.errorTimeout.text)
        }
    }

    private func finishRequest(with message: String?) {
        timeoutTask?.cancel()
        timeoutTask = nil
        isRequestingLocation = false
        manager.stopUpdatingLocation()
        errorMessage = message
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
            if isAuthorized {
                requestLocation()
            } else if status == .denied || status == .restricted {
                finishRequest(with: nil)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        Task { @MainActor in
            finishRequest(with: nil)
            location = newLocation
            errorMessage = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let nsError = error as NSError

        if nsError.domain == kCLErrorDomain,
           nsError.code == CLError.Code.locationUnknown.rawValue {
            return
        }

        let message = Self.message(for: error)
        Task { @MainActor in
            finishRequest(with: message)
        }
    }

    nonisolated private static func message(for error: Error) -> String {
        let nsError = error as NSError
        guard nsError.domain == kCLErrorDomain,
              let code = CLError.Code(rawValue: nsError.code) else {
            return Location.errorGeneric.text
        }

        switch code {
        case .denied:
            return Location.errorDenied.text
        case .network:
            return Location.errorNetwork.text
        default:
            return Location.errorTimeout.text
        }
    }
}
