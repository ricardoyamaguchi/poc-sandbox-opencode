import Foundation

protocol LocalizableStrings: RawRepresentable where RawValue == String {
    static var prefix: String { get }
    var localized: LocalizedStringResource { get }
}

extension LocalizableStrings {
    static var tableName: String {
        prefix.prefix(1).uppercased() + prefix.dropFirst()
    }

    var key: String {
        "\(Self.prefix).\(rawValue)"
    }

    var localized: LocalizedStringResource {
        LocalizedStringResource(String.LocalizationValue(key), table: Self.tableName)
    }

    var text: String {
        String(localized: String.LocalizationValue(key), table: Self.tableName)
    }

    func localized(with arguments: CVarArg...) -> String {
        String(format: text, locale: .current, arguments: arguments)
    }
}
