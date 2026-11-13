import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color.blue.opacity(0.14)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 20) {
                    Image(systemName: "swift")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 104, height: 104)
                        .background(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                        )
                        .shadow(color: .orange.opacity(0.35), radius: 18, y: 10)

                    Text("Bem-vindo ao PocSandbox")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text("Entre com sua conta Google para começar a usar o app.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 16) {
                    Button {
                        Task { await auth.signIn() }
                    } label: {
                        HStack(spacing: 12) {
                            if auth.isSigningIn {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                GoogleLogo()
                            }

                            Text(auth.isSigningIn ? "Entrando…" : "Continuar com Google")
                                .font(.headline)
                                .foregroundStyle(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            Color(.systemBackground),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                        }
                    }
                    .disabled(auth.isSigningIn)
                    .accessibilityLabel("Continuar com Google")

                    Text("Ao continuar, você concorda com os Termos de Uso e a Política de Privacidade.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .alert(
            "Não foi possível entrar",
            isPresented: Binding(
                get: { auth.errorMessage != nil },
                set: { if !$0 { auth.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { auth.errorMessage = nil }
        } message: {
            Text(auth.errorMessage ?? "")
        }
    }
}

private struct GoogleLogo: View {
    var body: some View {
        Text("G")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue, .red, .yellow, .green],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 24, height: 24)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
