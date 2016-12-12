import Foundation
import Sparkle
import ReactiveSwift

class UpdateManager {
    static let useDevChannel: MutableProperty<Bool> = MutableProperty(false)
    
    static func setUp() {
        let updater = SUUpdater.shared()!
        // force to update since this app is very likely to be buggy.
        updater.automaticallyChecksForUpdates = true
        // check for updates every hour
        updater.updateCheckInterval = 3600
        
        useDevChannel.producer.startWithValues {
            if $0 {
                updater.feedURL = URL(string: "https://zhuhaow.github.io/SpechtLite/devappcast.xml")
            } else {
                updater.feedURL = URL(string: "https://zhuhaow.github.io/SpechtLite/stableappcast.xml")
            }
        }
    }
}
