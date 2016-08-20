//
//  ProxyHelper.swift
//  SpechtLite
//
//  Created by 周斌佳 on 16/8/17.
//  Copyright © 2016年 Zhuhao Wang. All rights reserved.
//

import Foundation
import SystemConfiguration

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

    public static func install() {
        let fileManager = NSFileManager.defaultManager()
        if !fileManager.fileExistsAtPath(kProxyConfigPath) || !checkVersion() {
            let scriptPath = "\(NSBundle.mainBundle().resourcePath!)/install_proxy.sh"
            let appleScriptStr = "do shell script \"bash \(scriptPath)\" with administrator privileges"
            let appleScript = NSAppleScript(source: appleScriptStr)
            var dict: NSDictionary?
            if let _ = appleScript?.executeAndReturnError(&dict) {
                print("install script success")
            } else {
                print(dict)
                print("install script failed")
            }
        }
    }

    public static func setSystemProxy(port: Int, enable: Bool) -> Bool {
        let task = NSTask()
        task.launchPath = kProxyConfigPath
        task.arguments = [String(port), enable ? "enable" : "disable"]

        task.launch()

        task.waitUntilExit()

        if task.terminationStatus != 0 {
            return false
        }
        return true
    }
}