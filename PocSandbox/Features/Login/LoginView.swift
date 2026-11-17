import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(uiColor: .systemBackground), Theme.brand.opacity(0.14)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 20) {
                    Image(systemName: "swift")
                        .font(.largeTitle.weight(.semibold))
                        .imageScale(.large)
                        .symbolRenderingMode(.monochrome)
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

                    Text(Login.welcomeTitle.localized)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text(Login.welcomeSubtitle.localized)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 16) {
                    Button {
                        Task { await viewModel.signIn() }
                    } label: {
                        HStack(spacing: 12) {
                            if viewModel.isSigningIn {
                                ProgressView()
                                    .tint(.primary)
                            } else {
                                GoogleLogo()
                            }

                            Text(viewModel.isSigningIn ? Login.buttonSigningIn.localized : Login.buttonSignIn.localized)
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            Color(uiColor: .secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                        }
                    }
                    .disabled(viewModel.isSigningIn)
                    .accessibilityLabel(Text(Login.buttonSignIn.localized))

                    Text(Login.terms.localized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .alert(
            Text(Login.errorTitle.localized),
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button(Login.ok.localized, role: .cancel) { viewModel.clearError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private struct GoogleLogo: View {
    var body: some View {
        Text("G")
            .font(.title3.weight(.bold))
            .fontDesign(.rounded)
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
    LoginFlowView(authService: AuthService())
}
