import Cocoa

class Utils {
    static func alertError(_ errorDescription: String) {
        DispatchQueue.main.sync {
            let alert = NSAlert()
            alert.messageText = errorDescription
            alert.runModal()
        }
    }
}
