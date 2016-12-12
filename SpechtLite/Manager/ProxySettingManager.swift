import Foundation
import ReactiveSwift

class ProxySettingManager {
    static let setAsSystemProxy: MutableProperty<Bool> = MutableProperty(false)
    
    static func setup() {
        setAsSystemProxy.producer.combineLatest(with: ProfileManager.currentProxyPort.producer).startWithValues { enabled, port in
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
}
