import Cocoa
import NEKit
import Sparkle
import CocoaLumberjackSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    var fileLogger: DDFileLogger!
    var barItem: NSStatusItem!
    var configurations: [String: (String, Bool)] = [:]
    var currentConfiguration: String?
    
    var currentProxyPort = 9090
    var currentProxies: [ProxyServer] = []
    
    var updater: SUUpdater!
    
    var configFolder: String {
        let path = (NSHomeDirectory() as NSString).stringByAppendingPathComponent(".SpechtLite")
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
    
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        DDLog.addLogger(DDTTYLogger.sharedInstance(), withLevel: .Info)
        
        fileLogger = DDFileLogger()
        fileLogger.rollingFrequency = 60*60*3
        fileLogger.logFileManager.maximumNumberOfLogFiles = 1
        DDLog.addLogger(fileLogger, withLevel: .Info)
        
        ObserverFactory.currentFactory = SPObserverFactory()
        
        reloadAllConfigurationFiles()
        initMenuBar()
        
        updater = SUUpdater.sharedUpdater()
        // force to update since this app is very likely to be buggy.
        updater.automaticallyChecksForUpdates = true
        // check for updates every hour
        updater.updateCheckInterval = 3600
        
        setUpAutostart()
        
        if Preference.setUpSystemProxy {
            if !ProxyHelper.install() {
                alertError("Failed to install helper script to set up system proxy.")
                Preference.setUpSystemProxy = false
            } else {
                setUpSystemProxy(Preference.setUpSystemProxy)
            }
        }
    }
    
    func initMenuBar() {
        let icon = NSImage(named: "StatusIcon")
        icon?.template = true
        barItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
        barItem.image = icon
        barItem.menu = NSMenu()
        barItem.menu!.delegate = self
    }
    
    func menuNeedsUpdate(menu: NSMenu) {
        menu.removeAllItems()
        
        for name in configurations.keys.sort() {
            let item = buildMenuItemForManager(name, valid: configurations[name]!.1)
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItemWithTitle("Disconnect", action: #selector(AppDelegate.disconnect(_:)), keyEquivalent: "d")
        menu.addItemWithTitle("Open config folder", action: #selector(AppDelegate.openConfigFolder(_:)), keyEquivalent: "c")
        menu.addItemWithTitle("Reload config", action: #selector(AppDelegate.reloadClicked(_:)), keyEquivalent: "r")
        menu.addItem(NSMenuItem.separatorItem())
        let proxyItem = NSMenuItem(title: "Set as system proxy", action: #selector(AppDelegate.setProxyClicked(_:)), keyEquivalent: "")
        if Preference.setUpSystemProxy {
            proxyItem.state = NSOnState
        }
        menu.addItem(proxyItem)
        menu.addItemWithTitle("Copy shell export command", action: #selector(AppDelegate.copyCommand(_:)), keyEquivalent: "")
        let lanItem = NSMenuItem(title: "Allow Clients From Lan", action: #selector(AppDelegate.allowClientsFromLanClicked(_:)), keyEquivalent: "")
        if Preference.allowFromLan {
            lanItem.state = NSOnState
        }
        menu.addItem(lanItem)
        menu.addItem(NSMenuItem(title: "Speed test", action: #selector(AppDelegate.speedTestClicked(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separatorItem())
        let autostartItem = NSMenuItem(title: "Autostart at login", action: #selector(AppDelegate.autostartClicked(_:)), keyEquivalent: "")
        if Preference.autostart {
            autostartItem.state = NSOnState
        }
        menu.addItem(autostartItem)
        menu.addItemWithTitle("Check for updates", action: #selector(AppDelegate.update(_:)), keyEquivalent: "u")
        menu.addItemWithTitle("Show log", action: #selector(AppDelegate.showLogfile(_:)), keyEquivalent: "")
        menu.addItemWithTitle("About", action: #selector(AppDelegate.showAbout(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItemWithTitle("Exit", action: #selector(AppDelegate.terminate(_:)), keyEquivalent: "q")
    }
    
    func buildMenuItemForManager(name: String, valid: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: name, action: #selector(AppDelegate.startConfiguration(_:)), keyEquivalent: "")
        
        if name == currentConfiguration {
            item.state = NSOnState
        }
        
        if !valid {
            item.action = nil
        }
        
        return item
    }
    
    func startConfiguration(sender: NSMenuItem) {
        if sender.title == currentConfiguration {
            disconnect()
            return
        }
        
        disconnect()
        
        runConfiguration(sender.title)
    }
    
    func runConfiguration(name: String) -> Bool {
        let configuration = Configuration()
        
        guard let config = configurations[name] else {
            return false
        }
        
        guard config.1 else {
            return false
        }
        
        try! configuration.load(fromConfigString: config.0)
        RuleManager.currentManager = configuration.ruleManager
        let proxyPort = configuration.proxyPort ?? 9090
        
        let address = Preference.allowFromLan ? nil : IPv4Address(fromString: "127.0.0.1")
        let httpServer = GCDHTTPProxyServer(address: address, port: Port(port: UInt16(proxyPort)))
        let socks5Server = GCDSOCKS5ProxyServer(address: address, port: Port(port: UInt16(proxyPort + 1)))
        
        do {
            try httpServer.start()
            try socks5Server.start()
        } catch let error {
            alertError("Encounter an error when starting proxy server. \(error)")
            return false
        }
        
        currentProxyPort = proxyPort
        currentConfiguration = name
        currentProxies.append(httpServer)
        currentProxies.append(socks5Server)
        
        saveCurrentConfigurationToDefaults()
        return true
    }
    
    func disconnect(sender: AnyObject? = nil) {
        for proxyServer in currentProxies {
            proxyServer.stop()
        }
        currentProxies = []
        
        currentConfiguration = nil
    }
    
    func openConfigFolder(sender: AnyObject) {
        NSWorkspace.sharedWorkspace().openFile(configFolder)
    }
    
    func reloadClicked(sender: AnyObject) {
        reloadAllConfigurationFiles()
    }
    
    func setProxyClicked(sender: AnyObject) {
        if !ProxyHelper.install() {
            alertError("Failed to install helper script to set up system proxy.")
            Preference.setUpSystemProxy = false
        } else {
            Preference.setUpSystemProxy = !Preference.setUpSystemProxy
            setUpSystemProxy(Preference.setUpSystemProxy)
        }
    }
    
    func setUpSystemProxy(enabled: Bool) {
        if !ProxyHelper.setUpSystemProxy(currentProxyPort, enabled: enabled) {
            alertError("Failed to set up system proxy.")
            Preference.setUpSystemProxy = false
        }
    }
    
    func copyCommand(sender: AnyObject) {
        let pasteboard = NSPasteboard.generalPasteboard()
        pasteboard.clearContents()
        pasteboard.setString("export https_proxy=http://127.0.0.1:\(currentProxyPort);export http_proxy=http://127.0.0.1:\(currentProxyPort)", forType: NSStringPboardType)
    }
    
    func allowClientsFromLanClicked(sender: AnyObject) {
        Preference.allowFromLan = !Preference.allowFromLan
        if currentProxies.count > 0 {
            disconnect()
            runConfigurationInDefaults()
        }
    }
    
    func speedTestClicked(sender: AnyObject) {
        let t1 = NSDate().timeIntervalSince1970
        let proxySessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        proxySessionConfiguration.connectionProxyDictionary = [
            kCFNetworkProxiesHTTPSEnable: 1,
            kCFNetworkProxiesHTTPSPort: currentProxyPort,
            kCFNetworkProxiesHTTPSProxy: "127.0.0.1"
        ]
        let urlSession = NSURLSession(configuration: proxySessionConfiguration)
        let task = urlSession.dataTaskWithURL(NSURL(string: "https://www.google.com/generate_204")!) {
            (data, response, error) in
            let notification = NSUserNotification()
            notification.soundName = NSUserNotificationDefaultSoundName
            notification.title = "Speed Test"
            if let res = response as? NSHTTPURLResponse where res.statusCode == 204 {
                let time = Int((NSDate().timeIntervalSince1970 - t1) * 1000)
                notification.informativeText = "Response time: \(time)ms"
            } else {
                print("HTTP Request Failed")
                print(error)
                notification.informativeText = "Speed test failed!"
            }
            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
        }
        task.resume()
    }
    
    func autostartClicked(sender: AnyObject) {
        Preference.autostart = !Preference.autostart
        setUpAutostart()
    }
    
    func setUpAutostart() {
        if Preference.autostart {
            Autostart.enable()
        } else {
            Autostart.disable()
        }
    }
    
    func showLogfile(sender: AnyObject) {
        if let logfile = fileLogger.logFileManager.sortedLogFilePaths().first as? String {
            NSWorkspace.sharedWorkspace().selectFile(nil, inFileViewerRootedAtPath: logfile)
        }
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
                alertError("Error when loading config file: \(fullpath). \(error)")
                configurations[name] = ("", false)
                continue
            }
            
            let configuration = Configuration()
            do {
                try configuration.load(fromConfigString: content)
            } catch let error {
                alertError("Error when parsing config file: \(fullpath). \(error)")
                configurations[name] = ("", false)
                continue
            }
            
            configurations[name] = (content, true)
        }
        
        disconnect()
        if runDefault {
            runConfigurationInDefaults()
        }
    }
    
    func saveCurrentConfigurationToDefaults() {
        Preference.defaultConfiguration = currentConfiguration
    }
    
    func runConfigurationInDefaults() -> Bool {
        guard let configName = Preference.defaultConfiguration else {
            return false
        }
        
        return runConfiguration(configName)
    }
    
    func update(sender: AnyObject? = nil) {
        updater.checkForUpdates(sender)
    }
    
    func showAbout(sender: AnyObject? = nil) {
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
        NSApplication.sharedApplication().orderFrontStandardAboutPanel(sender)
    }
    
    func alertError(errorDescription: String) {
        let alert = NSAlert()
        alert.messageText = errorDescription
        alert.runModal()
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        if Preference.setUpSystemProxy {
            ProxyHelper.setUpSystemProxy(currentProxyPort, enabled: false)
        }
        disconnect()
    }
    
    func terminate(sender: AnyObject? = nil) {
        NSApp.terminate(self)
    }
}
