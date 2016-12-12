import Foundation
import ServiceManagement
import ReactiveSwift

class AutostartManager {
    static let identifier = "me.zhuhaow.osx.SpechtLite.LaunchHelper"
    
    static let autostartAtLogin: MutableProperty<Bool> = MutableProperty(false)
    
    static func setUp() {
        autostartAtLogin.producer.startWithValues {
            _ = $0 ? enable() : disable()
        }
    }

    @discardableResult
    static func enable() -> Bool {
        return SMLoginItemSetEnabled(identifier as CFString, true)
    }

    @discardableResult
    static func disable() -> Bool {
        return SMLoginItemSetEnabled(identifier as CFString, false)
    }
}
