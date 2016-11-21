import Cocoa

class Utils {
    static func alertError(errorDescription: String) {
        let alert = NSAlert()
        alert.messageText = errorDescription
        alert.runModal()
    }
}
