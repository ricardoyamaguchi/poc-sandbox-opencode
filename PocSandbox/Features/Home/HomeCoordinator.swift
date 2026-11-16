import SwiftUI
import UIKit

@MainActor
final class HomeCoordinator: ObservableObject {
    let viewModel: HomeViewModel

    init(authService: AuthService) {
        viewModel = HomeViewModel(
            authService: authService,
            locationProvider: LocationProvider(),
            cartStore: CartStore()
        )
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

struct HomeFlowView: View {
    @StateObject private var coordinator: HomeCoordinator

    init(authService: AuthService) {
        _coordinator = StateObject(wrappedValue: HomeCoordinator(authService: authService))
    }

    var body: some View {
        HomeView(viewModel: coordinator.viewModel, coordinator: coordinator)
    }
}
