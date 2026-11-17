import SwiftUI

private struct ExpandableListItemHeightPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]

    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct ExpandableListView<Item: Identifiable, Content: View, EmptyContent: View>: View {
    let title: Text
    let items: [Item]
    let height: CGFloat?
    @Binding var isExpanded: Bool
    @Binding var collapsedHeight: CGFloat
    let content: (Item) -> Content
    let emptyContent: () -> EmptyContent

    @State private var firstItemHeight: CGFloat = 0
    @State private var secondItemHeight: CGFloat = 0

    private let collapsedItemLimit = 2
    private let borderInset: CGFloat = 8
    private let itemSpacing: CGFloat = 12

    private var visibleItems: [Item] {
        isExpanded ? items : Array(items.prefix(collapsedItemLimit))
    }

    private var effectiveSecondItemHeight: CGFloat {
        if secondItemHeight > 0 {
            return secondItemHeight
        }
        if firstItemHeight > 0 {
            return firstItemHeight
        }
        return 0
    }

    private var halfSecondItemHeight: CGFloat? {
        let base = effectiveSecondItemHeight
        guard base > 0 else { return nil }
        return base / 2.0
    }

    private var collapsedListHeight: CGFloat? {
        guard firstItemHeight > 0 else { return nil }
        if items.count == 1 {
            return firstItemHeight
        } else {
            return firstItemHeight + itemSpacing + (effectiveSecondItemHeight / 2.0)
        }
    }

    init(
        title: Text,
        items: [Item],
        height: CGFloat? = nil,
        isExpanded: Binding<Bool>,
        collapsedHeight: Binding<CGFloat>,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) {
        self.title = title
        self.items = items
        self.height = height
        self._isExpanded = isExpanded
        self._collapsedHeight = collapsedHeight
        self.content = content
        self.emptyContent = emptyContent
    }

    init(
        title: LocalizedStringResource,
        items: [Item],
        height: CGFloat? = nil,
        isExpanded: Binding<Bool>,
        collapsedHeight: Binding<CGFloat>,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) {
        self.init(
            title: Text(title),
            items: items,
            height: height,
            isExpanded: isExpanded,
            collapsedHeight: collapsedHeight,
            content: content,
            emptyContent: emptyContent
        )
    }

    init(
        title: String,
        items: [Item],
        height: CGFloat? = nil,
        isExpanded: Binding<Bool>,
        collapsedHeight: Binding<CGFloat>,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) {
        self.init(
            title: Text(title),
            items: items,
            height: height,
            isExpanded: isExpanded,
            collapsedHeight: collapsedHeight,
            content: content,
            emptyContent: emptyContent
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            title
                .font(.headline)
                .foregroundStyle(Theme.ink)

            if items.isEmpty {
                emptyContent()
            } else {
                list

                if isExpanded {
                    closeButton
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: isExpanded ? .infinity : nil, alignment: .topLeading)
        .background(
            GeometryReader { proxy in
                Color.clear.onAppear {
                    if !isExpanded {
                        collapsedHeight = proxy.size.height
                    }
                }
                .onChange(of: proxy.size.height) { _, newHeight in
                    if !isExpanded {
                        collapsedHeight = newHeight
                    }
                }
            }
        )
        .padding(.horizontal, borderInset)
        .padding(.vertical, borderInset)
        .frame(height: height, alignment: .top)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.6), lineWidth: 0.5)
        }
        .onChange(of: items.count) { _, count in
            if count <= 1 && isExpanded {
                isExpanded = false
            }
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: itemSpacing) {
                ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                    let isSecondCollapsedItem = !isExpanded && index == 1

                    content(item)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(
                            Group {
                                if index < 2 {
                                    GeometryReader { proxy in
                                        Color.clear.preference(
                                            key: ExpandableListItemHeightPreferenceKey.self,
                                            value: [index: proxy.size.height]
                                        )
                                    }
                                }
                            }
                        )
                        .frame(maxHeight: isSecondCollapsedItem ? halfSecondItemHeight : nil, alignment: .top)
                        .clipped()
                        .mask {
                            if isSecondCollapsedItem {
                                LinearGradient(
                                    colors: [.black, .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            } else {
                                Color.black
                            }
                        }
                        .allowsHitTesting(!isSecondCollapsedItem)
                        .overlay {
                            if isSecondCollapsedItem {
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.snappy) {
                                            isExpanded = true
                                        }
                                    }
                                    .accessibilityAction {
                                        withAnimation(.snappy) {
                                            isExpanded = true
                                        }
                                    }
                                    .accessibilityLabel(Text(Carts.seeMore.localized))
                                    .accessibilityHint(Text(Carts.seeMoreAccessibilityHint.localized))
                            }
                        }
                }
            }
            .padding(.bottom, isExpanded ? 8 : 0)
        }
        .scrollDisabled(!isExpanded)
        .scrollIndicators(isExpanded ? .visible : .hidden)
        .frame(maxHeight: isExpanded ? .infinity : collapsedListHeight)
        .onPreferenceChange(ExpandableListItemHeightPreferenceKey.self) { heights in
            if let h0 = heights[0], h0 > 0 {
                firstItemHeight = h0
            }
            if let h1 = heights[1], h1 > 0 {
                secondItemHeight = h1
            }
        }
    }

    private var closeButton: some View {
        Button {
            withAnimation(.snappy) {
                isExpanded = false
            }
        } label: {
            Text(Carts.close.localized)
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
        .accessibilityLabel(Text(Carts.closeAccessibilityLabel.localized))
        .padding(.bottom, 8)
    }
}

extension ExpandableListView where Content == CartRowView<Item>, EmptyContent == CartEmptyView {
    init(
        title: LocalizedStringResource,
        items: [Item],
        height: CGFloat? = nil,
        isExpanded: Binding<Bool>,
        collapsedHeight: Binding<CGFloat>,
        onDelete: @escaping (Item) -> Void
    ) where Item: CartListItem {
        self.init(
            title: title,
            items: items,
            height: height,
            isExpanded: isExpanded,
            collapsedHeight: collapsedHeight,
            content: { item in
                CartRowView(item: item, onDelete: onDelete)
            },
            emptyContent: {
                CartEmptyView()
            }
        )
    }

    init(
        title: String,
        items: [Item],
        height: CGFloat? = nil,
        isExpanded: Binding<Bool>,
        collapsedHeight: Binding<CGFloat>,
        onDelete: @escaping (Item) -> Void
    ) where Item: CartListItem {
        self.init(
            title: title,
            items: items,
            height: height,
            isExpanded: isExpanded,
            collapsedHeight: collapsedHeight,
            content: { item in
                CartRowView(item: item, onDelete: onDelete)
            },
            emptyContent: {
                CartEmptyView()
            }
        )
    }
}

struct CartEmptyView: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "cart")
                .font(.title3)
                .foregroundStyle(Theme.ink)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(Carts.emptyTitle.localized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)

                Text(Carts.emptyMessage.localized)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }

            Spacer()
        }
        .padding(12)
        .cardStyle()
    }
}

struct CartRowView<Item: CartListItem>: View {
    let item: Item
    let onDelete: (Item) -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "cart")
                .font(.title3)
                .foregroundStyle(Theme.ink)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.marketName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                Text(Carts.rowSubtitle.localized(with: item.startedAtText, item.statusText))
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(item.totalText)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)

            Button {
                withAnimation(.snappy) {
                    onDelete(item)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.body)
                    .foregroundStyle(.red)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(Carts.deleteAccessibilityLabel.localized(with: item.marketName)))
        }
        .padding(12)
        .cardStyle()
    }
}

typealias CartsListView<Item: CartListItem> = ExpandableListView<Item, CartRowView<Item>, CartEmptyView>
