import Combine
import CoreLocation
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var markets: [Market] = []
    @Published var searchText = ""
    @Published private(set) var isLoadingMarkets = false
    @Published private(set) var marketsError: String?
    @Published private(set) var openCarts: [Cart] = []
    @Published private(set) var location: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var locationErrorMessage: String?
    @Published private(set) var email: String?
    @Published var showSignOutConfirmation = false

    private let authService: AuthService
    private let locationProvider: LocationProvider
    private let cartStore: CartStore
    private let marketService: MapKitMarketService
    private var cancellables = Set<AnyCancellable>()

    init(
        authService: AuthService,
        locationProvider: LocationProvider,
        cartStore: CartStore,
        marketService: MapKitMarketService = MapKitMarketService()
    ) {
        self.authService = authService
        self.locationProvider = locationProvider
        self.cartStore = cartStore
        self.marketService = marketService
        authorizationStatus = locationProvider.authorizationStatus
        location = locationProvider.location
        openCarts = cartStore.openCarts
        email = authService.email
        bind()
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var filteredMarkets: [Market] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return markets }
        return markets.filter { $0.name.localizedStandardContains(query) }
    }

    func onAppear() {
        requestLocationIfNeeded()
    }

    func onScenePhaseActive() {
        requestLocationIfNeeded()
    }

    func retryLocation() {
        requestLocationIfNeeded()
    }

    func refreshMarkets() async {
        if let location {
            await loadMarkets(near: location)
        } else {
            requestLocationIfNeeded()
        }
    }

    func startCart(at market: Market) {
        cartStore.startCart(at: market)
    }

    func closeCart(_ cart: Cart) {
        cartStore.close(cart)
    }

    func isCartOpen(for market: Market) -> Bool {
        openCarts.contains { $0.marketID == market.id }
    }

    func requestSignOut() {
        showSignOutConfirmation = true
    }

    func cancelSignOut() {
        showSignOutConfirmation = false
    }

    func signOut() {
        authService.signOut()
    }

    func distanceText(for market: Market) -> String? {
        guard let distance = market.distance(from: location) else { return nil }

        if distance < 1000 {
            return "\(Int(distance.rounded())) m"
        }

        return String(format: "%.1f km", locale: Locale.current, distance / 1000)
    }

    func dateText(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle(date: .numeric, time: .omitted)
                .locale(Locale(identifier: "pt_BR"))
        )
    }

    func currencyText(_ value: Double) -> String {
        value.formatted(
            .currency(code: "BRL")
                .locale(Locale(identifier: "pt_BR"))
        )
    }

    private func bind() {
        locationProvider.$authorizationStatus
            .assign(to: &$authorizationStatus)

        locationProvider.$errorMessage
            .assign(to: &$locationErrorMessage)

        locationProvider.$location
            .sink { [weak self] location in
                Task { @MainActor in
                    guard let self else { return }
                    self.location = location
                    guard let location else { return }
                    await self.loadMarkets(near: location)
                }
            }
            .store(in: &cancellables)

        cartStore.$openCarts
            .assign(to: &$openCarts)

        authService.$user
            .map { $0?.profile?.email }
            .assign(to: &$email)
    }

    private func requestLocationIfNeeded() {
        if authorizationStatus == .notDetermined {
            locationProvider.requestAuthorization()
        } else if isAuthorized {
            locationProvider.requestLocation()
        }
    }

    private func loadMarkets(near location: CLLocation) async {
        guard !isLoadingMarkets else { return }

        isLoadingMarkets = true
        marketsError = nil
        defer { isLoadingMarkets = false }

        do {
            markets = try await marketService.nearbyMarkets(around: location)
        } catch {
            marketsError = error.localizedDescription
        }
    }
}
