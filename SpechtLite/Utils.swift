import Cocoa

class Utils {
    static func alertError(_ errorDescription: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = errorDescription
            alert.runModal()
        }
    }
}
