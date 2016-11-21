import Cocoa
import NEKit

class ConfigurationManager {
    static let singletonInstance: ConfigurationManager = ConfigurationManager()
    
    var configurations: [String: (String, Bool)] = [:]
    var currentConfiguration: String?
    
    var currentProxyPort = 9090
    var currentProxies: [ProxyServer] = []
    
    var configFolder: String {
        let path = (NSHomeDirectory() as NSString).stringByAppendingPathComponent(Opt.configurationFolder)
        var isDir: ObjCBool = false
        let exist = NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir)
        if exist && !isDir {
            try! NSFileManager.defaultManager().removeItemAtPath(path)
            try! NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        }
        if !exist {
            try! NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        }
        return path
    }
    
    private init() {}
    
    func openConfigFolder() {
        NSWorkspace.sharedWorkspace().openFile(configFolder)
    }
    
    func reloadAllConfigurationFiles(runDefault: Bool = true) {
        configurations.removeAll()
        
        let paths = try! NSFileManager.defaultManager().contentsOfDirectoryAtPath(configFolder).filter {
            ($0 as NSString).pathExtension == "yaml"
        }
        
        for path in paths {
            let name = ((path as NSString).lastPathComponent as NSString).stringByDeletingPathExtension
            
            let fullpath = (configFolder as NSString).stringByAppendingPathComponent(path)
            
            var content: String
            do {
                content = try String(contentsOfFile: fullpath, encoding: NSUTF8StringEncoding)
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
            runDefaultConfiguration()
        }
    }
    
    func toggleConfiguration(name: String) {
        if name == currentConfiguration {
            stopProxyServer()
            return
        }
        
        stopProxyServer()
        
        runConfiguration(name)
    }
    
    func runConfiguration(name: String) -> Bool {
        guard let config = configurations[name] else {
            return false
        }
        
        guard config.1 else {
            return false
        }
        
        let configuration = Configuration()
        
        try! configuration.load(fromConfigString: config.0)
        RuleManager.currentManager = configuration.ruleManager
        currentProxyPort = configuration.proxyPort ?? 9090
        
        let address = Preference.allowFromLan ? nil : IPv4Address(fromString: "127.0.0.1")
        let httpServer = GCDHTTPProxyServer(address: address, port: Port(port: UInt16(currentProxyPort)))
        let socks5Server = GCDSOCKS5ProxyServer(address: address, port: Port(port: UInt16(currentProxyPort + 1)))
        
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
        runConfiguration(configName)
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
    
    func enumerateInOrder(block: (name: String, enabled: Bool) -> Void) {
        for name in configurations.keys.sort() {
            block(name: name, enabled: configurations[name]!.1)
        }
    }

}
