import SwiftUI

struct ContentView: View {
    @StateObject private var auth = AuthViewModel()

    var body: some View {
        Group {
            if auth.isRestoringSession {
                ProgressView("Verificando sessão…")
            } else if auth.isSignedIn {
                HomeView()
            } else {
                LoginView()
            }
        }
        .environmentObject(auth)
        .task {
            await auth.restorePreviousSignIn()
        }
    }
}

#Preview {
    ContentView()
}
