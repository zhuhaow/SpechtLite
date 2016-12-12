import Foundation
import ReactiveSwift

class PreferenceManager {
    static let defaultProfileKey = "defaultConfiguration"
    static let allowFromLanKey = "allowFromLan"
    static let setAsSystemProxyKey = "setUpSystemProxy"
    static let useDevChannelKey = "useDevChannel"
    static let autostartKey = "autostart"
    
    static func setUp() {
        let defaults = UserDefaults.standard
        ProfileManager.currentProfile.swap(defaults.string(forKey: defaultProfileKey))
        ProfileManager.allowFromLan.swap(defaults.bool(forKey: allowFromLanKey))
        ProxySettingManager.setAsSystemProxy.swap(defaults.bool(forKey: setAsSystemProxyKey))
        UpdateManager.useDevChannel.swap(defaults.bool(forKey: useDevChannelKey))
        AutostartManager.autostartAtLogin.swap(defaults.bool(forKey: autostartKey))
        
        ProfileManager.currentProfile.signal.skipRepeats(==).observeValues {
            defaults.set($0, forKey: defaultProfileKey)
        }
        
        ProfileManager.allowFromLan.signal.skipRepeats(==).observeValues {
            defaults.set($0, forKey: allowFromLanKey)
        }
        
        ProxySettingManager.setAsSystemProxy.signal.skipRepeats(==).observeValues {
            defaults.set($0, forKey: setAsSystemProxyKey)
        }
        
        UpdateManager.useDevChannel.signal.skipRepeats(==).observeValues {
            defaults.set($0, forKey: useDevChannelKey)
        }
        
        AutostartManager.autostartAtLogin.signal.skipRepeats(==).observeValues {
            defaults.set($0, forKey: autostartKey)
        }
    }
}
