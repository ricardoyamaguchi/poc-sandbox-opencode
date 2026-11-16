import GoogleSignIn
import SwiftUI

@main
struct PocSandboxApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
