import Cocoa
import NEKit
import ReactiveSwift

class ProfileManager {
    static let profiles: MutableProperty<[String:String]> = MutableProperty([:])
    static let profileNames: Property<[String]> = Property(profiles.map {
        return $0.keys.sorted()
    })
    static let currentProfile: MutableProperty<String?> = MutableProperty(nil)
    static let currentProxyPort: MutableProperty<UInt16?> = MutableProperty(nil)
    static let allowFromLan: MutableProperty<Bool> = MutableProperty(false)
    
    static private var currentProxies: [ProxyServer] = []
    
    static var profileFolder: String {
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
    
    static func setUp() {
        reloadAllProfileFiles()
        
        profiles.producer.startWithValues { _ in
            currentProfile.modify { _ in }
        }
        
        currentProfile.producer.startWithValues { name in
            runProfile(name: name)
        }
        
        allowFromLan.producer.startWithValues { _ in
            runProfile(name: currentProfile.value)
        }
    }
    
    static func openProfileFolder() {
        NSWorkspace.shared().openFile(profileFolder)
    }
    
    static func reloadAllProfileFiles() {
        var _profiles: [String:String] = [:]
        
        let paths = try! FileManager.default.contentsOfDirectory(atPath: profileFolder).filter {
            ($0 as NSString).pathExtension == "yaml"
        }
        
        for path in paths {
            let name = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
            
            let fullpath = (profileFolder as NSString).appendingPathComponent(path)
            
            var content: String
            do {
                content = try String(contentsOfFile: fullpath, encoding: String.Encoding.utf8)
            } catch let error {
                Utils.alertError("Error when loading profile file: \(fullpath). \(error)")
                return
            }
            
            let configuration = Configuration()
            do {
                try configuration.load(fromConfigString: content)
            } catch let error {
                Utils.alertError("Error when parsing profile file: \(fullpath). \(error)")
                return
            }
            
            _profiles[name] = content
        }
        
        profiles.swap(_profiles)
    }
    
    @discardableResult
    static private func runProfile(name: String?) -> Bool {
        stopProxyServer()
        
        guard let name = name else {
            currentProxyPort.swap(nil)
            return true
        }
        
        guard let profile = profiles.value[name] else {
            return false
        }
        
        let configuration = Configuration()
        
        try! configuration.load(fromConfigString: profile)
        RuleManager.currentManager = configuration.ruleManager
        let newPort = UInt16(configuration.proxyPort ?? Opt.defaultProxyPort)
        
        let address = allowFromLan.value ? nil : IPAddress(fromString: "127.0.0.1")
        let httpServer = GCDHTTPProxyServer(address: address, port: NEKit.Port(port: newPort))
        let socks5Server = GCDSOCKS5ProxyServer(address: address, port: NEKit.Port(port: newPort + 1))
        
        do {
            try httpServer.start()
            try socks5Server.start()
        } catch let error {
            Utils.alertError("Encounter an error when starting proxy server. \(error)")
            httpServer.stop()
            socks5Server.stop()
            return false
        }
        
        currentProxies.append(httpServer)
        currentProxies.append(socks5Server)

        currentProxyPort.swap(newPort)

        return true
    }
    
    static func stopProxyServer() {
        for proxyServer in currentProxies {
            proxyServer.stop()
        }
        currentProxies = []
    }
}
