import Foundation

open class ProxyHelper {

    static let kProxyConfigPath = "/Library/Application Support/SpechtLite/ProxyConfig"
    static let kVersion = "0.4.0"

    open static func checkVersion() -> Bool {
        let task = Process()
        task.launchPath = kProxyConfigPath
        task.arguments = ["version"]

        let pipe = Pipe()
        task.standardOutput = pipe
        let fd = pipe.fileHandleForReading
        task.launch()

        task.waitUntilExit()

        if task.terminationStatus != 0 {
            return false
        }

        let res = String(data: fd.readDataToEndOfFile(), encoding: String.Encoding.utf8) ?? ""
        if res.contains(kVersion) {
            return true
        }
        return false
    }

    open static func install() -> Bool {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: kProxyConfigPath) || !checkVersion() {
            let scriptPath = "\(Bundle.main.resourcePath!)/install_proxy_helper.sh"
            let appleScriptStr = "do shell script \"bash \(scriptPath)\" with administrator privileges"
            let appleScript = NSAppleScript(source: appleScriptStr)
            var dict: NSDictionary?
            if let _ = appleScript?.executeAndReturnError(&dict) {
                return true
            } else {
                return false
            }
        }
        return true
    }

    open static func setUpSystemProxy(port: UInt16?) -> Bool {
        let task = Process()
        task.launchPath = kProxyConfigPath
        if let port = port {
            task.arguments = [String(port), "enable"]
        } else {
            task.arguments = ["0", "disable"]
        }

        task.launch()

        task.waitUntilExit()

        if task.terminationStatus != 0 {
            return false
        }
        return true
    }
}
