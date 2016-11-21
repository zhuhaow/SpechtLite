import Foundation

class UserDefault {
    static func setString(_ value: String?, forKey: String) {
        UserDefaults.standard.set(value, forKey: forKey)
    }

    static func stringForKey(_ key: String) -> String? {
        return UserDefaults.standard.object(forKey: key) as? String
    }

    static func setBool(_ value: Bool, forKey: String) {
        UserDefaults.standard.set(value, forKey: forKey)
    }

    static func boolForKey(_ key: String) -> Bool {
        return UserDefaults.standard.bool(forKey: key)
    }

    static func synchronize() {
        UserDefaults.standard.synchronize()
    }
}
