import Foundation
import ReactiveSwift

class ProxySettingManager {
    static let setAsSystemProxy: MutableProperty<Bool> = MutableProperty(false)

    static func setUp() {
        setAsSystemProxy.signal.combineLatest(with: ProfileManager.currentProxyPort.signal).observeValues { enabled, port in
            var port = port
            if !enabled {
                port = nil
            }

            if !ProxyHelper.install() {
                Utils.alertError("Failed to install helper script to set up system proxy.")
            } else {
                if !ProxyHelper.setUpSystemProxy(port: port) {
                    Utils.alertError("Failed to set up system proxy.")
                }
            }
        }
    }

    static func clear() {
        if setAsSystemProxy.value {
            if !ProxyHelper.install() {
                Utils.alertError("Failed to install helper script to clear system proxy.")
            } else {
                if !ProxyHelper.setUpSystemProxy(port: nil) {
                    Utils.alertError("Failed to clear system proxy.")
                }
            }
        }
    }
}
