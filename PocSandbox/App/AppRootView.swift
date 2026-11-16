import SwiftUI

struct AppRootView: View {
    @StateObject private var coordinator = AppCoordinator()

    var body: some View {
        Group {
            switch coordinator.route {
            case .loading:
                ProgressView("Verificando sessão…")
            case .login:
                LoginFlowView(authService: coordinator.authService)
            case .home:
                HomeFlowView(authService: coordinator.authService)
            }
        }
        .task {
            await coordinator.start()
        }
    }
}

#Preview {
    AppRootView()
}
