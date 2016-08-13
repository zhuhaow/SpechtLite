import Foundation

class Preference {
    static var defaultConfiguration: String? {
        get {
            return UserDefault.stringForKey("currentConfiguration")
        }
        set {
            UserDefault.setString(newValue, forKey: "defaultConfiguration")
        }
    }
}
