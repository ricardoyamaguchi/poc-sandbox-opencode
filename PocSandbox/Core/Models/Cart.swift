import Combine
import Foundation

struct Cart: Identifiable, Codable, Hashable {
    let id: UUID
    let marketID: String
    let marketName: String
    let marketAddress: String
    let startedAt: Date
    var itemCount: Int
    var total: Double

    init(id: UUID = UUID(), market: Market, startedAt: Date = .now) {
        self.id = id
        self.marketID = market.id
        self.marketName = market.name
        self.marketAddress = market.address
        self.startedAt = startedAt
        self.itemCount = 0
        self.total = 0
    }
}

@MainActor
final class CartStore: ObservableObject {
    @Published private(set) var openCarts: [Cart] = []

    private let storageKey = "openCarts"
    private let defaults = UserDefaults.standard

    init() {
        load()
    }

    func startCart(at market: Market) {
        guard !openCarts.contains(where: { $0.marketID == market.id }) else { return }
        openCarts.insert(Cart(market: market), at: 0)
        save()
    }

    func close(_ cart: Cart) {
        openCarts.removeAll { $0.id == cart.id }
        save()
    }

    private func load() {
        guard
            let data = defaults.data(forKey: storageKey),
            let carts = try? JSONDecoder().decode([Cart].self, from: data)
        else {
            return
        }

        openCarts = carts
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(openCarts) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
