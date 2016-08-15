import Foundation

class UserDefault {
    static func setString(value: String?, forKey: String) {
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: forKey)
    }

    static func stringForKey(key: String) -> String? {
        return NSUserDefaults.standardUserDefaults().objectForKey(key) as? String
    }

    static func setBool(value: Bool, forKey: String) {
        NSUserDefaults.standardUserDefaults().setBool(value, forKey: forKey)
    }

    static func boolForKey(key: String) -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey(key)
    }

    static func synchronize() {
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
