import Foundation

class UserDefault {
    static func setString(value: String?, forKey: String) {
        NSUserDefaults.standardUserDefaults().setObject(value, forKey: forKey)
    }

    static func stringForKey(key: String) -> String? {
        return NSUserDefaults.standardUserDefaults().objectForKey(key) as? String
    }

    static func synchronize() {
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
