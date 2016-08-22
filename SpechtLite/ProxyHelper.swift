import Foundation

public class ProxyHelper {

    static let kProxyConfigPath = "/Library/Application Support/SpechtLite/ProxyConfig"
    static let kVersion = "0.1.0"

    public static func checkVersion() -> Bool {
        let task = NSTask()
        task.launchPath = kProxyConfigPath
        task.arguments = ["version"]

        let pipe = NSPipe()
        task.standardOutput = pipe
        let fd = pipe.fileHandleForReading
        task.launch()

        task.waitUntilExit()

        if task.terminationStatus != 0 {
            return false
        }

        let res = String(data: fd.readDataToEndOfFile(), encoding: NSUTF8StringEncoding) ?? ""
        if res.containsString(kVersion) {
            return true
        }
        return false
    }

    public static func install() -> Bool {
        let fileManager = NSFileManager.defaultManager()
        if !fileManager.fileExistsAtPath(kProxyConfigPath) || !checkVersion() {
            let scriptPath = "\(NSBundle.mainBundle().resourcePath!)/install_proxy_helper.sh"
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

    public static func setUpSystemProxy(port: Int, enabled: Bool) -> Bool {
        let task = NSTask()
        task.launchPath = kProxyConfigPath
        task.arguments = [String(port), enabled ? "enable" : "disable"]

        task.launch()

        task.waitUntilExit()

        if task.terminationStatus != 0 {
            return false
        }
        return true
    }
}
