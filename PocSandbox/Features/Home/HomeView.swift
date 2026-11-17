import CoreLocation
import SwiftUI

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var coordinator: HomeCoordinator
    @State private var isCartsExpanded = false
    @State private var collapsedCartsHeight: CGFloat = 0

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

                        ExpandableListView(
                            title: Home.cartsTitle.localized,
                            items: viewModel.openCarts,
                            height: isCartsExpanded ? expandedHeight : nil,
                            isExpanded: $isCartsExpanded,
                            collapsedHeight: $collapsedCartsHeight,
                            onDelete: { cart in
                                viewModel.closeCart(cart)
                            }
                        )
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
                Home.signOutTitle.localized,
                isPresented: $viewModel.showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button(Home.signOutConfirm.localized, role: .destructive) { viewModel.signOut() }
                Button(Home.signOutCancel.localized, role: .cancel) { viewModel.cancelSignOut() }
            }
            .onAppear { viewModel.onAppear() }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                viewModel.onScenePhaseActive()
            }
            .onChange(of: viewModel.openCarts.count) { _, count in
                if count <= 1 { isCartsExpanded = false }
            }
        }
    }

    private var header: some View {
        HStack {
            Text(Home.headerBadge.localized)
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
                    Label(Home.menuSignOut.localized, systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "cart")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(Text(Home.accountAccessibilityLabel.localized))
        }
    }

    private var questionSection: some View {
        Text(Home.questionTitle.localized)
            .font(.title2.weight(.bold))
            .foregroundStyle(Theme.ink)
    }

    private var marketsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Home.marketsTitle.localized)
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

            TextField(Home.searchPlaceholder.text, text: $viewModel.searchText)
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
                .accessibilityLabel(Text(Home.searchClearAccessibilityLabel.localized))
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
            statusCard(Home.locationRequesting.text)
        } else if viewModel.isLoadingMarkets {
            statusCard(Home.marketsLoading.text)
        } else if let locationError = viewModel.locationErrorMessage,
                  viewModel.location == nil {
            locationErrorCard(locationError)
        } else if viewModel.location == nil {
            statusCard(Home.locationLoading.text)
        } else if let marketsError = viewModel.marketsError {
            statusCard(marketsError)
        } else if viewModel.markets.isEmpty {
            statusCard(Home.marketsEmpty.text)
        } else if viewModel.filteredMarkets.isEmpty {
            statusCard(Home.marketsEmptySearch.localized(with:
                viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
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
            Text(Home.locationPermission.localized)
                .font(.footnote)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .mutedCardStyle()
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(Home.locationPermissionAccessibilityHint.localized))
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
        .accessibilityHint(Text(isOpen ? Home.marketOpenCartAccessibilityHint.localized : Home.marketStartCartAccessibilityHint.localized))
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
        .accessibilityHint(Text(Home.locationRetryAccessibilityHint.localized))
    }
}

#Preview {
    HomeFlowView(authService: AuthService())
}
