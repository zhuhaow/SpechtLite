import Cocoa

class Utils {
    static func alertError(_ errorDescription: String) {
        let alert = NSAlert()
        alert.messageText = errorDescription
        alert.runModal()
    }
}
