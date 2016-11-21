import Foundation
import Sparkle

class UpdaterManager {
    static func setUpAutoUpdate() {
        let updater = SUUpdater.shared()!
        // force to update since this app is very likely to be buggy.
        updater.automaticallyChecksForUpdates = true
        // check for updates every hour
        updater.updateCheckInterval = 3600
        
        if Preference.useDevChannel {
            updater.feedURL = URL(string: "https://zhuhaow.github.io/SpechtLite/devappcast.xml")
        } else {
            updater.feedURL = URL(string: "https://zhuhaow.github.io/SpechtLite/stableappcast.xml")
        }
    }
}
