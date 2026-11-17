import Foundation

protocol CartListItem: Identifiable {
    var marketName: String { get }
    var startedAt: Date { get }
    var total: Double { get }
    var statusText: String { get }
}

extension CartListItem {
    var statusText: String { Carts.status.text }

    var startedAtText: String {
        startedAt.formatted(
            Date.FormatStyle(date: .numeric, time: .omitted)
                .locale(Locale(identifier: "pt_BR"))
        )
    }

    var totalText: String {
        total.formatted(
            .currency(code: "BRL")
                .locale(Locale(identifier: "pt_BR"))
        )
    }
}
