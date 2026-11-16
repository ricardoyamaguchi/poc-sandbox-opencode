import CoreLocation
import SwiftUI

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var coordinator: HomeCoordinator

    private let horizontalPadding: CGFloat = 16

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 10)
                    .padding(.bottom, 18)

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        cartsSection
                        questionSection
                        marketsSection
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .refreshable { await viewModel.refreshMarkets() }
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog(
                "Deseja sair da sua conta Google?",
                isPresented: $viewModel.showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sair", role: .destructive) { viewModel.signOut() }
                Button("Cancelar", role: .cancel) { viewModel.cancelSignOut() }
            }
            .onAppear { viewModel.onAppear() }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                viewModel.onScenePhaseActive()
            }
        }
    }

    private var header: some View {
        HStack {
            Text("CARRINHO")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(Theme.brand)

            Spacer()

            Menu {
                if let email = viewModel.email {
                    Text(email)
                }

                Button(role: .destructive) {
                    viewModel.requestSignOut()
                } label: {
                    Label("Sair da conta", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "cart")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }
            .accessibilityLabel("Conta")
        }
    }

    private var cartsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Seus carrinhos")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.ink)

            if viewModel.openCarts.isEmpty {
                emptyCartsCard
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.openCarts) { cart in
                        cartRow(cart)
                    }
                }
            }
        }
    }

    private var emptyCartsCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "cart")
                .font(.system(size: 22))
                .foregroundStyle(Theme.ink)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text("Nenhum carrinho em aberto.")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink)

                Text("Toque em um mercado para começar.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
            }

            Spacer()
        }
        .padding(12)
        .cardStyle()
    }

    private var questionSection: some View {
        Text("Onde você está comprando?")
            .font(.system(size: 27, weight: .bold))
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private var marketsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mercados perto de você")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.muted)

            searchField

            marketsContent
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.muted)

            TextField("Digite o nome do mercado", text: $viewModel.searchText)
                .font(.system(size: 14))
                .foregroundStyle(Theme.ink)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.muted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Limpar busca")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .cardStyle()
    }

    @ViewBuilder
    private var marketsContent: some View {
        if viewModel.isDenied {
            permissionCard
        } else if viewModel.authorizationStatus == .notDetermined {
            statusCard("Solicitando acesso à localização…")
        } else if viewModel.isLoadingMarkets {
            statusCard("Buscando mercados próximos…")
        } else if let locationError = viewModel.locationErrorMessage,
                  viewModel.location == nil {
            locationErrorCard(locationError)
        } else if viewModel.location == nil {
            statusCard("Obtendo sua localização…")
        } else if let marketsError = viewModel.marketsError {
            statusCard(marketsError)
        } else if viewModel.markets.isEmpty {
            statusCard("Nenhum mercado encontrado por perto.")
        } else if viewModel.filteredMarkets.isEmpty {
            statusCard("Nenhum mercado encontrado para \"\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))\".")
        } else {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredMarkets) { market in
                    marketRow(market)
                }
            }
        }
    }

    private var permissionCard: some View {
        Button(action: coordinator.openSettings) {
            Text("Permita o acesso à localização para ver mercados próximos.")
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.ink)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .mutedCardStyle()
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Abre os Ajustes para permitir a localização")
    }

    private func cartRow(_ cart: Cart) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "cart")
                .font(.system(size: 26))
                .foregroundStyle(Theme.ink)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(cart.marketName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                Text("\(viewModel.dateText(cart.startedAt)) • em andamento")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(viewModel.currencyText(cart.total))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
        }
        .padding(12)
        .cardStyle()
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(.snappy) {
                    viewModel.closeCart(cart)
                }
            } label: {
                Label("Encerrar carrinho", systemImage: "xmark.circle")
            }
        }
    }

    private func marketRow(_ market: Market) -> some View {
        let isOpen = viewModel.isCartOpen(for: market)

        return Button {
            withAnimation(.snappy) {
                viewModel.startCart(at: market)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "storefront")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 3) {
                    Text(market.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)

                    if !market.address.isEmpty {
                        Text(market.address)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.muted)
                            .lineLimit(2)
                    }

                    if let distance = viewModel.distanceText(for: market) {
                        Text(distance)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.brand)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: isOpen ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(isOpen ? Theme.muted : Theme.brand)
            }
            .padding(12)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityHint(isOpen ? "Carrinho já está em aberto" : "Inicia uma nova compra neste mercado")
    }

    private func statusCard(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 14))
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .mutedCardStyle()
    }

    private func locationErrorCard(_ message: String) -> some View {
        Button(action: viewModel.retryLocation) {
            HStack(spacing: 12) {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.brand)
            }
            .padding(16)
            .mutedCardStyle()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Tenta obter sua localização novamente")
    }
}

#Preview {
    HomeFlowView(authService: AuthService())
}
