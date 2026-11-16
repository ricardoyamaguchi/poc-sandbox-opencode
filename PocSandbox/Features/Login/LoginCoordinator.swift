import SwiftUI

@MainActor
final class LoginCoordinator: ObservableObject {
    let viewModel: LoginViewModel

    init(authService: AuthService) {
        viewModel = LoginViewModel(authService: authService)
    }
}

struct LoginFlowView: View {
    @StateObject private var coordinator: LoginCoordinator

    init(authService: AuthService) {
        _coordinator = StateObject(wrappedValue: LoginCoordinator(authService: authService))
    }

    var body: some View {
        LoginView(viewModel: coordinator.viewModel)
    }
}
