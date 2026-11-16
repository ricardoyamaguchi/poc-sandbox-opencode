import CoreLocation
import MapKit

enum MarketSearchError: LocalizedError {
    case failed

    var errorDescription: String? {
        "Não foi possível buscar mercados próximos. Verifique sua conexão e tente novamente."
    }
}

struct MapKitMarketService {
    func nearbyMarkets(around location: CLLocation, radius: CLLocationDistance = 5_000) async throws -> [Market] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "supermercado"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )
        request.resultTypes = .pointOfInterest

        do {
            let response = try await MKLocalSearch(request: request).start()
            var seen = Set<String>()

            let markets = response.mapItems.compactMap { item -> Market? in
                guard let market = market(from: item) else { return nil }
                guard market.distance(from: location) ?? .greatestFiniteMagnitude <= radius else { return nil }
                guard seen.insert(market.id).inserted else { return nil }
                return market
            }

            return markets.sorted {
                ($0.distance(from: location) ?? .greatestFiniteMagnitude) <
                    ($1.distance(from: location) ?? .greatestFiniteMagnitude)
            }
        } catch {
            throw MarketSearchError.failed
        }
    }

    private func market(from item: MKMapItem) -> Market? {
        let coordinate: CLLocationCoordinate2D
        let address: String

        if #available(iOS 26.0, *) {
            coordinate = item.location.coordinate
            address = item.address?.fullAddress ?? ""
        } else {
            let placemark = item.placemark
            coordinate = placemark.coordinate
            address = placemark.title ?? ""
        }

        let name = item.name ?? "Mercado sem nome"
        let id = "\(coordinate.latitude),\(coordinate.longitude),\(name)"

        return Market(
            id: id,
            name: name,
            address: address,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}
