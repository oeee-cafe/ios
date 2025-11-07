import Foundation

extension String {
    /// Returns the localized version of this string
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    /// Returns the localized version of this string with arguments
    func localized(_ arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}
