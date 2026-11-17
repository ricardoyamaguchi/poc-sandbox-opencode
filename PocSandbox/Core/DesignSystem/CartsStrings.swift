import Foundation

enum Carts: String, LocalizableStrings {
    static let prefix = "carts"

    case status
    case rowSubtitle = "row.subtitle"
    case seeMore = "seeMore"
    case seeMoreAccessibilityHint = "seeMore.accessibilityHint"
    case close
    case closeAccessibilityLabel = "close.accessibilityLabel"
    case emptyTitle = "empty.title"
    case emptyMessage = "empty.message"
    case deleteAccessibilityLabel = "delete.accessibilityLabel"
}
