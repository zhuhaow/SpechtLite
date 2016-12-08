import Cocoa
import NEKit

class ConfigurationManager {
    static let singletonInstance: ConfigurationManager = ConfigurationManager()
    
    var configurations: [String: (String, Bool)] = [:]
    var currentConfiguration: String?
    
    var currentProxyPort = 9090
    var currentProxies: [ProxyServer] = []
    
    var configFolder: String {
        let path = (NSHomeDirectory() as NSString).appendingPathComponent(Opt.configurationFolder)
        var isDir: ObjCBool = false
        let exist = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        if exist && !isDir.boolValue {
            try! FileManager.default.removeItem(atPath: path)
            try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        if !exist {
            try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        return path
    }
    
    fileprivate init() {}
    
    func openConfigFolder() {
        NSWorkspace.shared().openFile(configFolder)
    }
    
    func reloadAllConfigurationFiles(_ runDefault: Bool = true) {
        configurations.removeAll()
        
        let paths = try! FileManager.default.contentsOfDirectory(atPath: configFolder).filter {
            ($0 as NSString).pathExtension == "yaml"
        }
        
        for path in paths {
            let name = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
            
            let fullpath = (configFolder as NSString).appendingPathComponent(path)
            
            var content: String
            do {
                content = try String(contentsOfFile: fullpath, encoding: String.Encoding.utf8)
            } catch let error {
                Utils.alertError("Error when loading config file: \(fullpath). \(error)")
                configurations[name] = ("", false)
                continue
            }
            
            let configuration = Configuration()
            do {
                try configuration.load(fromConfigString: content)
            } catch let error {
                Utils.alertError("Error when parsing config file: \(fullpath). \(error)")
                configurations[name] = ("", false)
                continue
            }
            
            configurations[name] = (content, true)
        }
        
        stopProxyServer()
        if runDefault {
            _ = runDefaultConfiguration()
        }
    }
    
    func toggleConfiguration(_ name: String) {
        if name == currentConfiguration {
            stopProxyServer()
            return
        }
        
        stopProxyServer()
        
        _ = runConfiguration(name)
    }
    
    func runConfiguration(_ name: String) -> Bool {
        guard let config = configurations[name] else {
            return false
        }
        
        guard config.1 else {
            return false
        }
        
        let configuration = Configuration()
        
        try! configuration.load(fromConfigString: config.0)
        RuleManager.currentManager = configuration.ruleManager
        let previousProxyPort = currentProxyPort
        currentProxyPort = configuration.proxyPort ?? 9090
        
        let address = Preference.allowFromLan ? nil : IPv4Address(fromString: "127.0.0.1")
        let httpServer = GCDHTTPProxyServer(address: address, port: NEKit.Port(port: UInt16(currentProxyPort)))
        let socks5Server = GCDSOCKS5ProxyServer(address: address, port: NEKit.Port(port: UInt16(currentProxyPort + 1)))
        
        do {
            try httpServer.start()
            try socks5Server.start()
        } catch let error {
            Utils.alertError("Encounter an error when starting proxy server. \(error)")
            httpServer.stop()
            socks5Server.stop()
            return false
        }
        
        currentConfiguration = name
        currentProxies.append(httpServer)
        currentProxies.append(socks5Server)
        
        if previousProxyPort != currentProxyPort && Preference.setUpSystemProxy {
            if !ProxyHelper.setUpSystemProxy(currentProxyPort, enabled: true) {
                Utils.alertError("Failed to change system proxy settings.")
                Preference.setUpSystemProxy = false
            }
        }
        
        saveCurrentConfigurationToDefaults()
        return true
    }
    
    func stopProxyServer() {
        for proxyServer in currentProxies {
            proxyServer.stop()
        }
        currentProxies = []
        
        currentConfiguration = nil
    }
    
    func restartCurrentProxyServer() {
        guard let configName = currentConfiguration else {
            return
        }
        
        stopProxyServer()
        _ = runConfiguration(configName)
    }
    
    func saveCurrentConfigurationToDefaults() {
        Preference.defaultConfiguration = currentConfiguration
    }
    
    func runDefaultConfiguration() -> Bool {
        guard let configName = Preference.defaultConfiguration else {
            return false
        }
        
        return runConfiguration(configName)
    }
    
    func enumerateInOrder(_ block: (_ name: String, _ enabled: Bool) -> Void) {
        for name in configurations.keys.sorted() {
            block(name, configurations[name]!.1)
        }
    }
    
}
