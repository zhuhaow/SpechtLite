import Foundation
import ServiceManagement

class Autostart {
    static let identifier = "me.zhuhaow.osx.SpechtLiteLaunchHelper"

    static func enable() -> Bool {
        return SMLoginItemSetEnabled(identifier, true)
    }

    static func disable() -> Bool {
        return SMLoginItemSetEnabled(identifier, false)
    }
}
