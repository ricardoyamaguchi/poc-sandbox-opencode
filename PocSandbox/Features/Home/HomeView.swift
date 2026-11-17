import CoreLocation
import SwiftUI

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var coordinator: HomeCoordinator
    @State private var isCartsExpanded = false
    @State private var collapsedCartsHeight: CGFloat = 0
    @State private var collapsedListHeight: CGFloat = 0

    private let horizontalPadding: CGFloat = 16
    private let cartsBorderInset: CGFloat = 8

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 10)
                    .padding(.bottom, 18)

                GeometryReader { proxy in
                    let expandedHeight = max(collapsedCartsHeight, proxy.size.height)

                    ZStack(alignment: .topLeading) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 28) {
                                Color.clear
                                    .frame(height: collapsedCartsHeight)
                                questionSection
                                marketsSection
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.bottom, 24)
                        }
                        .scrollIndicators(.hidden)
                        .scrollDismissesKeyboard(.interactively)
                        .refreshable { await viewModel.refreshMarkets() }

                        cartsBlock(height: isCartsExpanded ? expandedHeight : nil)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(.horizontal, cartsBorderInset)
                            .offset(y: isCartsExpanded ? 0 : -cartsBorderInset)
                            .zIndex(isCartsExpanded ? 1 : 0)
                    }
                }
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
            .onChange(of: viewModel.openCarts.count) { _, count in
                if count <= 2 { isCartsExpanded = false }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("CARRINHO")
                .font(.caption.weight(.bold))
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
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Conta")
        }
    }

    private func cartsBlock(height: CGFloat?) -> some View {
        let carts = isCartsExpanded ? viewModel.openCarts : Array(viewModel.openCarts.prefix(2))

        return VStack(alignment: .leading, spacing: 14) {
            Text("Seus carrinhos")
                .font(.headline)
                .foregroundStyle(Theme.ink)

            if viewModel.openCarts.isEmpty {
                emptyCartsCard
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(carts) { cart in
                            cartRow(cart)
                        }

                        if viewModel.openCarts.count > 2 && !isCartsExpanded {
                            seeMoreChip
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding(.bottom, isCartsExpanded ? 8 : 0)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.onAppear {
                                if !isCartsExpanded { collapsedListHeight = proxy.size.height }
                            }
                            .onChange(of: proxy.size.height) { _, newHeight in
                                if !isCartsExpanded { collapsedListHeight = newHeight }
                            }
                        }
                    )
                }
                .scrollDisabled(!isCartsExpanded)
                .scrollIndicators(isCartsExpanded ? .visible : .hidden)
                .frame(maxHeight: isCartsExpanded ? .infinity : (collapsedListHeight > 0 ? collapsedListHeight : nil))

                if isCartsExpanded {
                    Button {
                        withAnimation(.snappy) {
                            isCartsExpanded = false
                        }
                    } label: {
                        Text("Fechar")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.brand)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Theme.card)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Theme.brand.opacity(0.25), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Fechar lista de carrinhos")
                    .padding(.bottom, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: isCartsExpanded ? .infinity : nil, alignment: .topLeading)
        .background(
            GeometryReader { proxy in
                Color.clear.onAppear {
                    if !isCartsExpanded {
                        collapsedCartsHeight = proxy.size.height
                    }
                }
                .onChange(of: proxy.size.height) { _, newHeight in
                    if !isCartsExpanded {
                        collapsedCartsHeight = newHeight
                    }
                }
            }
        )
        .padding(.horizontal, cartsBorderInset)
        .padding(.vertical, cartsBorderInset)
        .frame(height: height, alignment: .top)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.6), lineWidth: 0.5)
        }
    }

    private var seeMoreChip: some View {
        Button {
            withAnimation(.snappy) {
                isCartsExpanded = true
            }
        } label: {
            Text("Ver mais")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.brand)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.card)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Theme.brand.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityHint("Exibe todos os carrinhos em aberto")
    }

    private var emptyCartsCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "cart")
                .font(.title3)
                .foregroundStyle(Theme.ink)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text("Nenhum carrinho em aberto.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)

                Text("Toque em um mercado para começar.")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }

            Spacer()
        }
        .padding(12)
        .cardStyle()
    }

    private var questionSection: some View {
        Text("Onde você está comprando?")
            .font(.title2.weight(.bold))
            .foregroundStyle(Theme.ink)
    }

    private var marketsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mercados perto de você")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.muted)

            searchField

            marketsContent
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.muted)

            TextField("Digite o nome do mercado", text: $viewModel.searchText)
                .font(.body)
                .foregroundStyle(Theme.ink)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
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
                .font(.footnote)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading)
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
                .font(.title3)
                .foregroundStyle(Theme.ink)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(cart.marketName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                Text("\(viewModel.dateText(cart.startedAt)) • em andamento")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(viewModel.currencyText(cart.total))
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)

            Button {
                withAnimation(.snappy) {
                    viewModel.closeCart(cart)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.body)
                    .foregroundStyle(.red)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Excluir carrinho de \(cart.marketName)")
        }
        .padding(12)
        .cardStyle()
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
                    .font(.title3)
                    .foregroundStyle(Theme.ink)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 3) {
                    Text(market.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)

                    if !market.address.isEmpty {
                        Text(market.address)
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                            .lineLimit(2)
                    }

                    if let distance = viewModel.distanceText(for: market) {
                        Text(distance)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.brand)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: isOpen ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title3)
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
            .font(.callout)
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .mutedCardStyle()
    }

    private func locationErrorCard(_ message: String) -> some View {
        Button(action: viewModel.retryLocation) {
            HStack(spacing: 12) {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.clockwise")
                    .font(.body.weight(.semibold))
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
