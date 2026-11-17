import Foundation

enum Location: String, LocalizableStrings {
    static let prefix = "location"

    case errorTimeout = "error.timeout"
    case errorGeneric = "error.generic"
    case errorDenied = "error.denied"
    case errorNetwork = "error.network"
}
