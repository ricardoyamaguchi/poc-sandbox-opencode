import Combine
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published private(set) var isSigningIn: Bool
    @Published private(set) var errorMessage: String?

    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()

    init(authService: AuthService) {
        self.authService = authService
        isSigningIn = authService.isSigningIn
        errorMessage = authService.errorMessage
        bind()
    }

    func signIn() async {
        await authService.signIn()
    }

    func clearError() {
        authService.errorMessage = nil
    }

    private func bind() {
        authService.$isSigningIn
            .sink { [weak self] isSigningIn in
                self?.isSigningIn = isSigningIn
            }
            .store(in: &cancellables)

        authService.$errorMessage
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
            }
            .store(in: &cancellables)
    }
}
