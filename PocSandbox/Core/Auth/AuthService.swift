import Foundation
import GoogleSignIn
import UIKit

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var user: GIDGoogleUser?
    @Published private(set) var isRestoringSession = true
    @Published private(set) var isSigningIn = false
    @Published var errorMessage: String?

    private let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String ?? ""

    var isSignedIn: Bool { user != nil }
    var isConfigured: Bool { !clientID.isEmpty && !clientID.contains("placeholder") }

    var displayName: String {
        user?.profile?.name ?? Auth.defaultUserName.text
    }

    var email: String? {
        user?.profile?.email
    }

    var avatarURL: URL? {
        user?.profile?.imageURL(withDimension: 160)
    }

    init() {
        guard isConfigured else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    func restorePreviousSignIn() async {
        guard isConfigured else {
            isRestoringSession = false
            return
        }

        defer { isRestoringSession = false }

        do {
            user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
        } catch {
            user = nil
        }
    }

    func signIn() async {
        guard !isSigningIn else { return }

        guard isConfigured else {
            errorMessage = Auth.errorMissingClientID.text
            return
        }

        guard let presenter = Self.presentingViewController() else {
            errorMessage = Auth.errorPresenter.text
            return
        }

        isSigningIn = true
        defer { isSigningIn = false }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            user = result.user
            errorMessage = nil
        } catch {
            let nsError = error as NSError
            let isCanceled = nsError.domain == kGIDSignInErrorDomain
                && nsError.code == GIDSignInError.canceled.rawValue
            guard !isCanceled else { return }
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        user = nil
    }

    private static func presentingViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        guard let root = scene?.windows.first(where: \.isKeyWindow)?.rootViewController else {
            return nil
        }
        return topViewController(from: root)
    }

    private static func topViewController(from viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return topViewController(from: presented)
        }
        if let navigation = viewController as? UINavigationController,
           let visible = navigation.visibleViewController {
            return topViewController(from: visible)
        }
        if let tabBar = viewController as? UITabBarController,
           let selected = tabBar.selectedViewController {
            return topViewController(from: selected)
        }
        return viewController
    }
}
