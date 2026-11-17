import Foundation

enum Auth: String, LocalizableStrings {
    static let prefix = "auth"

    case defaultUserName
    case errorMissingClientID = "error.missingClientID"
    case errorPresenter = "error.presenter"
}
