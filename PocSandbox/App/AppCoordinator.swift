import Combine
import Foundation

@MainActor
final class AppCoordinator: ObservableObject {
    enum Route {
        case loading
        case login
        case home
    }

    @Published private(set) var route: Route = .loading
    let authService: AuthService

    private var cancellables = Set<AnyCancellable>()

    init(authService: AuthService? = nil) {
        self.authService = authService ?? AuthService()
        bind()
    }

    func start() async {
        await authService.restorePreviousSignIn()
    }

    private func bind() {
        authService.$isRestoringSession
            .combineLatest(authService.$user)
            .sink { [weak self] isRestoringSession, user in
                guard let self else { return }

                if isRestoringSession {
                    self.route = .loading
                } else {
                    self.route = user == nil ? .login : .home
                }
            }
            .store(in: &cancellables)
    }
}
