import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                avatar

                VStack(spacing: 6) {
                    Text(auth.displayName)
                        .font(.title2.bold())

                    if let email = auth.email {
                        Text(email)
                            .foregroundStyle(.secondary)
                    }
                }

                Label("Sessão iniciada com o Google", systemImage: "checkmark.seal.fill")
                    .font(.footnote)
                    .foregroundStyle(.green)

                Spacer()

                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    Label("Sair da conta", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(24)
            .navigationTitle("Início")
            .confirmationDialog(
                "Deseja sair da sua conta Google?",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sair", role: .destructive) { auth.signOut() }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }

    @ViewBuilder
    private var avatar: some View {
        AsyncImage(url: auth.avatarURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 112, height: 112)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
